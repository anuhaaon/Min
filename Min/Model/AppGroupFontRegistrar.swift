//
//  AppGroupFontRegistrar.swift
//  Min
//
//  从 App Group 注册主 App 已下载的自定义字体（供主 App / Widget 共用）
//  真机 Widget：先拷到扩展沙盒再内存注册，避免 chronod 读 App Group 字体文件失败
//

import Foundation
import CoreText
import UIKit

enum AppGroupFontRegistrar {
    private static let appGroupID = AppGroupStore.suiteName
    private static var registeredStorageNames = Set<String>()
    private static var postScriptByStorageName: [String: String] = [:]
    private static var uiFontCache: [String: String] = [:] // storage -> psName verified with UIFont

    private static var appGroupFontsDirectoryURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("Fonts", isDirectory: true)
    }

    /// Widget 扩展本地缓存目录（chronod 对 App Group 字体文件常拒绝读）
    private static var extensionFontsDirectoryURL: URL? {
        guard Bundle.main.bundleURL.pathExtension == "appex" else { return nil }
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return base.appendingPathComponent("WidgetFonts", isDirectory: true)
    }

    /// 按 App Group 存储文件名注册，返回真实 PostScript 名
    @discardableResult
    static func registerStorageFileName(_ storageFileName: String) -> String? {
        if let cached = uiFontCache[storageFileName],
           UIFont(name: cached, size: 12) != nil {
            return cached
        }

        guard let sourceURL = resolveSourceURL(storageFileName: storageFileName) else {
            print("AppGroupFontRegistrar: 找不到字体文件 \(storageFileName)")
            return nil
        }

        // Widget：拷到扩展自己的 Caches，降低 App Group 文件保护 / 沙盒问题
        let urlToRegister: URL
        if let extDir = extensionFontsDirectoryURL {
            do {
                try FileManager.default.createDirectory(at: extDir, withIntermediateDirectories: true)
                let local = extDir.appendingPathComponent(storageFileName)
                if !FileManager.default.fileExists(atPath: local.path) {
                    try FileManager.default.copyItem(at: sourceURL, to: local)
                }
                try? FileManager.default.setAttributes(
                    [.protectionKey: FileProtectionType.none],
                    ofItemAtPath: local.path
                )
                urlToRegister = local
                print("AppGroupFontRegistrar: Widget 已缓存到扩展沙盒 \(storageFileName)")
            } catch {
                print("AppGroupFontRegistrar: 拷贝到扩展失败，改用 App Group 源文件: \(error)")
                urlToRegister = sourceURL
            }
        } else {
            urlToRegister = sourceURL
        }

        return registerFontFile(at: urlToRegister, storageFileName: storageFileName)
    }

    /// 兼容旧逻辑：按原始 fileName / PostScript 尝试注册
    @discardableResult
    static func registerIfNeeded(preferringPostScriptName preferredName: String? = nil) -> String? {
        if let preferredName, !preferredName.isEmpty,
           UIFont(name: preferredName, size: 12) != nil {
            return preferredName
        }

        if let preferredName,
           let item = ODRFontCatalog.all.first(where: { $0.postScriptName == preferredName }) {
            return registerStorageFileName(item.storageFileName)
        }

        guard let dir = appGroupFontsDirectoryURL,
              let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
        else { return nil }

        for url in files where ["ttf", "otf"].contains(url.pathExtension.lowercased()) {
            let name = url.lastPathComponent
            if let resolved = registerStorageFileName(name) {
                if preferredName == nil { continue }
                if preferredName == resolved || UIFont(name: preferredName!, size: 12) != nil {
                    return resolved
                }
            }
        }
        return preferredName.flatMap { UIFont(name: $0, size: 12) != nil ? $0 : nil }
    }

    @discardableResult
    static func registerFileName(_ fileName: String) -> String? {
        if let item = ODRFontCatalog.all.first(where: { $0.fileName == fileName }) {
            return registerStorageFileName(item.storageFileName)
        }
        return registerStorageFileName(fileName)
    }

    // MARK: - Private

    private static func resolveSourceURL(storageFileName: String) -> URL? {
        if let dir = appGroupFontsDirectoryURL {
            let url = dir.appendingPathComponent(storageFileName)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        if let extDir = extensionFontsDirectoryURL {
            let url = extDir.appendingPathComponent(storageFileName)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    @discardableResult
    private static func registerFontFile(at url: URL, storageFileName: String) -> String? {
        if let cached = uiFontCache[storageFileName],
           UIFont(name: cached, size: 12) != nil {
            return cached
        }

        // 1) 从数据创建描述符并注册到进程，避免再读磁盘（替代已弃用的 GraphicsFont）
        var psName: String?
        var shouldRegisterViaURL = true
        if let data = try? Data(contentsOf: url),
           let descriptors = CTFontManagerCreateFontDescriptorsFromData(data as CFData) as? [CTFontDescriptor],
           let first = descriptors.first {
            psName = CTFontDescriptorCopyAttribute(first, kCTFontNameAttribute) as? String
            let alreadyUsable = psName.map { UIFont(name: $0, size: 12) != nil } ?? false
            if alreadyUsable {
                shouldRegisterViaURL = false
            } else {
                CTFontManagerRegisterFontDescriptors(descriptors as CFArray, .process, true, nil)
            }
        }

        // 2) 再注册 URL（.process），双保险
        if shouldRegisterViaURL {
            var urlError: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &urlError)
        }

        if psName == nil || psName?.isEmpty == true {
            psName = postScriptNames(from: url)?.first
        }

        guard let resolved = psName, !resolved.isEmpty else {
            print("AppGroupFontRegistrar: 无 PostScript 名 \(storageFileName)")
            return nil
        }

        let wasKnown = registeredStorageNames.contains(storageFileName)
        registeredStorageNames.insert(storageFileName)
        postScriptByStorageName[storageFileName] = resolved

        if UIFont(name: resolved, size: 12) == nil {
            print("AppGroupFontRegistrar: 注册后 UIFont 仍不可用 \(resolved)")
        } else {
            uiFontCache[storageFileName] = resolved
            if !wasKnown {
                print("AppGroupFontRegistrar: 注册成功 \(storageFileName) → \(resolved)")
            }
        }
        return resolved
    }

    private static func postScriptNames(from url: URL) -> [String]? {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] else {
            return nil
        }
        return descriptors.compactMap { desc in
            CTFontDescriptorCopyAttribute(desc, kCTFontNameAttribute) as? String
        }
    }
}
