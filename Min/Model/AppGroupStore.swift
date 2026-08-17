//
//  AppGroupStore.swift
//  Min
//
//  统一 App Group UserDefaults 访问，避免 synchronize / 重复实例导致 CFPrefs 异常
//

import Foundation
import WidgetKit

enum AppGroupStore {
    static let suiteName = "group.HaoDeng.Min.MinWidget"

    /// 缓存同一 suite，勿反复创建 + synchronize
    static let defaults: UserDefaults? = UserDefaults(suiteName: suiteName)

    private static var reloadWorkItem: DispatchWorkItem?
    private static var lastReloadAt: Date = .distantPast

    static func data(forKey key: String) -> Data? {
        defaults?.data(forKey: key)
    }

    static func string(forKey key: String) -> String? {
        defaults?.string(forKey: key)
    }

    static func object(forKey key: String) -> Any? {
        defaults?.object(forKey: key)
    }

    static func double(forKey key: String) -> Double {
        defaults?.double(forKey: key) ?? 0
    }

    static func set(_ value: Any?, forKey key: String) {
        guard let defaults else {
            print("AppGroupStore: UserDefaults suite 不可用")
            return
        }
        if let value {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }

    static func setData(_ data: Data?, forKey key: String) {
        set(data, forKey: key)
    }

    static func setCodable<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            set(data, forKey: key)
        } catch {
            print("AppGroupStore: 编码失败 \(key): \(error)")
        }
    }

    static func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    /// 合并多次保存，避免疯狂 reload 打崩小组件
    static func reloadWidgetsDebounced(delay: TimeInterval = 0.8) {
        reloadWorkItem?.cancel()
        let work = DispatchWorkItem {
            let now = Date()
            // 限流：短时间内反复保存时，只触发一次真正的 timelines reload。
            guard now.timeIntervalSince(lastReloadAt) >= 1.5 else { return }
            lastReloadAt = now
            WidgetCenter.shared.reloadAllTimelines()
        }
        reloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
