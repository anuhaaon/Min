//
//  AppStoreIconStore.swift
//  Min
//
//  运行时从 iTunes Search 拉取第三方 App 图标并缓存。
//  系统内置 App 不请求接口，改用 SF Symbol，避免内置商标图。
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppStoreIconStore: ObservableObject {
    static let shared = AppStoreIconStore()

    @Published private(set) var images: [String: UIImage] = [:]
    @Published private(set) var loadingNames: Set<String> = []

    private var inflight: Set<String> = []
    private var pending: [String] = []
    private let maxConcurrent = 4
    private let diskDirectory: URL
    private let session: URLSession

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskDirectory = caches.appendingPathComponent("AppStoreIcons", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    func image(for name: String) -> UIImage? {
        images[name]
    }

    func isLoading(_ name: String) -> Bool {
        loadingNames.contains(name)
    }

    func request(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard images[trimmed] == nil else { return }
        guard !inflight.contains(trimmed), !pending.contains(trimmed) else { return }
        if SystemAppSymbol.isSystem(trimmed) { return }
        loadingNames.insert(trimmed)
        pending.append(trimmed)
        pump()
    }

    private func pump() {
        while inflight.count < maxConcurrent, !pending.isEmpty {
            let name = pending.removeFirst()
            inflight.insert(name)
            Task { [weak self] in
                await self?.fetch(name)
                self?.inflight.remove(name)
                self?.pump()
            }
        }
    }

    private func fetch(_ name: String) async {
        defer { loadingNames.remove(name) }

        let file = diskFile(for: name)
        if let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            images[name] = image
            return
        }

        guard let artworkURL = await lookupArtworkURL(for: name) else { return }
        do {
            let (data, _) = try await session.data(from: artworkURL)
            guard let image = UIImage(data: data) else { return }
            try? data.write(to: file, options: .atomic)
            images[name] = image
        } catch {
            return
        }
    }

    private func lookupArtworkURL(for name: String) async -> URL? {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(encoded)&country=cn&entity=software&limit=8") else {
            return nil
        }
        do {
            let (data, _) = try await session.data(from: url)
            let result = try JSONDecoder().decode(SearchResult.self, from: data)
            let match = result.results.first { $0.trackName.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
                ?? result.results.first { $0.trackName.contains(name) || name.contains($0.trackName) }
                ?? result.results.first
            guard let raw = match?.artworkUrl60 else { return nil }
            let retina = raw
                .replacingOccurrences(of: "60x60", with: "120x120")
                .replacingOccurrences(of: "100x100", with: "120x120")
            return URL(string: retina)
        } catch {
            return nil
        }
    }

    private func diskFile(for name: String) -> URL {
        let safe = name.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : "_" }
        return diskDirectory.appendingPathComponent(String(safe) + ".png")
    }
}

enum SystemAppSymbol {
    static func isSystem(_ name: String) -> Bool {
        map[name] != nil
    }

    static func symbolName(for name: String) -> String? {
        map[name]
    }

    private static let map: [String: String] = [
        "短信": "message.fill",
        "照片": "photo.fill",
        "Safari": "safari.fill",
        "邮件": "envelope.fill",
        "日历": "calendar",
        "备忘录": "note.text",
        "地图": "map.fill",
        "天气": "cloud.sun.fill",
        "时钟": "clock.fill",
        "音乐": "music.note",
        "App Store": "square.grid.2x2.fill",
        "钱包": "wallet.pass.fill",
        "FaceTime": "video.fill",
        "提醒事项": "checklist",
        "文件": "folder.fill",
        "播客": "headphones",
        "图书": "book.fill",
        "快捷指令": "square.stack.3d.up.fill",
        "健康": "heart.fill",
        "密码": "key.fill",
        "查找": "location.magnifyingglass",
        "家庭": "house.fill",
        "健身": "figure.run",
        "语音备忘录": "waveform",
        "新闻": "newspaper.fill",
        "TV": "tv.fill",
        "股票": "chart.line.uptrend.xyaxis",
        "无边记": "pencil.and.outline",
        "日记": "book.closed.fill",
        "电话": "phone.fill",
        "通讯录": "person.crop.circle.fill"
    ]
}

struct AppStoreIconView: View {
    let name: String
    var size: CGFloat = 35

    @ObservedObject private var store = AppStoreIconStore.shared

    var body: some View {
        Group {
            if let image = store.image(for: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let symbol = SystemAppSymbol.symbolName(for: name) {
                Image(systemName: symbol)
                    .resizable()
                    .scaledToFit()
                    .padding(7)
                    .foregroundStyle(.white.opacity(0.85))
            } else if store.isLoading(name) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.45))
                    .scaleEffect(0.72)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(6)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .frame(width: size, height: size)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .task {
            store.request(name)
        }
    }
}
