//
//  ODRFontManager.swift
//  Min
//
//  ODR 字体下载、注册，并复制到 App Group 供 Widget 使用
//

import Foundation
import CoreText
import Combine
import WidgetKit

@MainActor
final class ODRFontManager: ObservableObject {
    static let shared = ODRFontManager()

    enum Status: Equatable {
        case notDownloaded
        case downloading(progress: Double)
        case ready
        case failed(String)
    }

    @Published private(set) var statusByTag: [String: Status] = [:]

    private let appGroupID = AppGroupStore.suiteName
    private var activeRequests: [String: NSBundleResourceRequest] = [:]
    private var inFlightTasks: [String: Task<Void, Error>] = [:]

    private var fontsDirectoryURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("Fonts", isDirectory: true)
    }

    private init() {
        refreshLocalStatus()
        registerAllLocalFonts()
    }

    func status(for tag: String) -> Status {
        statusByTag[tag] ?? .notDownloaded
    }

    func isReady(_ item: ODRFontItem) -> Bool {
        if case .ready = status(for: item.odrTag) { return true }
        return localURL(for: item) != nil
    }

    func refreshLocalStatus() {
        var map: [String: Status] = [:]
        for tag in ODRFontCatalog.allTags {
            let items = ODRFontCatalog.items(tag: tag)
            let allLocal = items.allSatisfy { localURL(for: $0) != nil }
            map[tag] = allLocal ? .ready : .notDownloaded
        }
        statusByTag = map
    }

    func localURL(for item: ODRFontItem) -> URL? {
        guard let dir = fontsDirectoryURL else { return nil }
        let url = dir.appendingPathComponent(item.storageFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    @discardableResult
    func ensureDownloaded(tag: String) async throws -> [(item: ODRFontItem, storageFileName: String, postScriptName: String)] {
        if case .ready = status(for: tag),
           ODRFontCatalog.items(tag: tag).allSatisfy({ localURL(for: $0) != nil }) {
            return registerItems(ODRFontCatalog.items(tag: tag))
        }

        if let existing = inFlightTasks[tag] {
            try await existing.value
            return registerItems(ODRFontCatalog.items(tag: tag))
        }

        let task = Task { @MainActor in
            try await self.performDownload(tag: tag)
        }
        inFlightTasks[tag] = task
        defer { inFlightTasks[tag] = nil }
        try await task.value
        return registerItems(ODRFontCatalog.items(tag: tag))
    }

    func ensureDownloaded(item: ODRFontItem) async throws -> (storageFileName: String, postScriptName: String) {
        let results = try await ensureDownloaded(tag: item.odrTag)
        if let hit = results.first(where: { $0.item.id == item.id }) {
            return (hit.storageFileName, hit.postScriptName)
        }
        let ps = AppGroupFontRegistrar.registerStorageFileName(item.storageFileName) ?? item.postScriptName
        return (item.storageFileName, ps)
    }

    func registerAllLocalFonts() {
        for item in ODRFontCatalog.all where localURL(for: item) != nil {
            _ = AppGroupFontRegistrar.registerStorageFileName(item.storageFileName)
        }
    }

    // MARK: - Private

    private func performDownload(tag: String) async throws {
        if case .ready = status(for: tag),
           ODRFontCatalog.items(tag: tag).allSatisfy({ localURL(for: $0) != nil }) {
            _ = registerItems(ODRFontCatalog.items(tag: tag))
            return
        }

        statusByTag[tag] = .downloading(progress: 0)
        let items = ODRFontCatalog.items(tag: tag)

        // 1) 若 Bundle 里已经能直接读到（Debug 嵌入 Asset Pack / 已缓存在本地），跳过网络
        if items.allSatisfy({ bundleURL(for: $0) != nil }) {
            do {
                try copyItemsFromBundleToAppGroup(items)
                statusByTag[tag] = .ready
                AppGroupStore.reloadWidgetsDebounced()
                return
            } catch {
                print("ODRFontManager: 本地 Bundle 拷贝失败，改走 ODR: \(error)")
            }
        }

        let request = NSBundleResourceRequest(tags: [tag])
        request.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
        activeRequests[tag] = request

        let progress = request.progress
        let observation = progress.observe(\.fractionCompleted, options: [.new]) { [weak self] prog, _ in
            Task { @MainActor in
                self?.statusByTag[tag] = .downloading(progress: prog.fractionCompleted)
            }
        }

        do {
            try await request.beginAccessingResources()
            observation.invalidate()

            try copyItemsFromBundleToAppGroup(items)
            statusByTag[tag] = .ready

            // 已拷贝到 App Group，立即结束访问，避免占住 ODR 会话导致后续 Tag「无法连接服务器」
            request.endAccessingResources()
            activeRequests[tag] = nil

            AppGroupStore.reloadWidgetsDebounced()
        } catch {
            observation.invalidate()
            request.endAccessingResources()
            activeRequests[tag] = nil

            // 2) ODR 服务器失败时再试一次 Bundle（部分 Tag 可能已在本地）
            if items.allSatisfy({ bundleURL(for: $0) != nil }) {
                do {
                    try copyItemsFromBundleToAppGroup(items)
                    statusByTag[tag] = .ready
                    AppGroupStore.reloadWidgetsDebounced()
                    print("ODRFontManager: ODR 失败，已用本地 Bundle 回退成功 tag=\(tag)")
                    return
                } catch {
                    print("ODRFontManager: Bundle 回退也失败: \(error)")
                }
            }

            statusByTag[tag] = .failed(error.localizedDescription)
            throw error
        }
    }

    private func copyItemsFromBundleToAppGroup(_ items: [ODRFontItem]) throws {
        guard let destDir = fontsDirectoryURL else {
            throw NSError(domain: "ODRFontManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法访问 App Group"])
        }
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        for item in items {
            guard let src = bundleURL(for: item) else {
                throw NSError(domain: "ODRFontManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "找不到字体资源 \(item.fileName)"])
            }
            let dest = destDir.appendingPathComponent(item.storageFileName)
            let data = try Data(contentsOf: src)
            try data.write(to: dest, options: .atomic)
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.none],
                ofItemAtPath: dest.path
            )
            print("ODRFontManager: 已写入 App Group \(item.storageFileName) (\(data.count) bytes)")
        }
    }

    private func bundleURL(for item: ODRFontItem) -> URL? {
        let name = (item.fileName as NSString).deletingPathExtension
        let ext = (item.fileName as NSString).pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext)
            ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Fonts")
    }

    @discardableResult
    private func registerItems(_ items: [ODRFontItem]) -> [(item: ODRFontItem, storageFileName: String, postScriptName: String)] {
        var result: [(item: ODRFontItem, storageFileName: String, postScriptName: String)] = []
        for item in items {
            if let bundleURL = bundleURL(for: item) {
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(bundleURL as CFURL, .process, &error)
            }
            let ps = AppGroupFontRegistrar.registerStorageFileName(item.storageFileName) ?? item.postScriptName
            result.append((item, item.storageFileName, ps))
        }
        return result
    }
}
