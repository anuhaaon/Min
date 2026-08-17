//
//  FontSetting.swift
//  Min
//
//  Created by dh on 2025/10/5.
//


import Foundation
import SwiftUI
import CoreLocation
#if canImport(WeatherKit)
import WeatherKit
#endif

/// 顶部 Widget 类型枚举
enum TopWidgetType: String, Codable, CaseIterable {
    case time = "time"
    case date = "date"
    case empty = "empty"
    case weather = "weather"
    
    var displayName: String {
        switch self {
        case .time: return "时间"
        case .date: return "日期"
        case .empty: return "空白"
        case .weather: return "天气"
        }
    }
}

/// 字体设置数据模型
struct FontSetting: Codable, Equatable {
    var fontSize: FontSize
    var customFont: CustomFont
    var fontColor: FontColor
    var customFontSize: CGFloat  // 自定义字体大小 (30-50)
    var customColorRGB: (red: Double, green: Double, blue: Double, alpha: Double)?  // 自定义颜色 RGB 值
    var backgroundImageName: String?  // 背景图片文件名
    var topWidgetType: TopWidgetType?  // 顶部 Widget 类型；新安装默认空白
    /// 文字间距，0–20，默认 10
    var fontSpacing: CGFloat
    
    init(fontSize: FontSize = .medium, customFont: CustomFont = CustomFont(fontName: .system, style: .regular), fontColor: FontColor = .white, customFontSize: CGFloat = 45, customColorRGB: (red: Double, green: Double, blue: Double, alpha: Double)? = nil, backgroundImageName: String? = nil, topWidgetType: TopWidgetType? = .empty, fontSpacing: CGFloat = 10) {
        self.fontSize = fontSize
        self.customFont = customFont
        self.fontColor = fontColor
        self.customFontSize = customFontSize
        self.customColorRGB = customColorRGB
        self.backgroundImageName = backgroundImageName
        self.topWidgetType = topWidgetType
        self.fontSpacing = fontSpacing
    }
    
    // 自定义 Codable 实现
    enum CodingKeys: String, CodingKey {
        case fontSize, customFont, fontColor, customFontSize
        case customColorRed, customColorGreen, customColorBlue, customColorAlpha
        case backgroundImageName
        case topWidgetType
        case fontSpacing
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fontSize = try container.decode(FontSize.self, forKey: .fontSize)
        customFont = try container.decode(CustomFont.self, forKey: .customFont)
        fontColor = try container.decode(FontColor.self, forKey: .fontColor)
        customFontSize = try container.decode(CGFloat.self, forKey: .customFontSize)
        
        if let red = try? container.decode(Double.self, forKey: .customColorRed),
           let green = try? container.decode(Double.self, forKey: .customColorGreen),
           let blue = try? container.decode(Double.self, forKey: .customColorBlue),
           let alpha = try? container.decode(Double.self, forKey: .customColorAlpha) {
            customColorRGB = (red: red, green: green, blue: blue, alpha: alpha)
        } else {
            customColorRGB = nil
        }
        
        backgroundImageName = try? container.decode(String.self, forKey: .backgroundImageName)
        topWidgetType = try? container.decode(TopWidgetType.self, forKey: .topWidgetType)
        fontSpacing = (try? container.decode(CGFloat.self, forKey: .fontSpacing)) ?? 10
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(customFont, forKey: .customFont)
        try container.encode(fontColor, forKey: .fontColor)
        try container.encode(customFontSize, forKey: .customFontSize)
        
        if let rgb = customColorRGB {
            try container.encode(rgb.red, forKey: .customColorRed)
            try container.encode(rgb.green, forKey: .customColorGreen)
            try container.encode(rgb.blue, forKey: .customColorBlue)
            try container.encode(rgb.alpha, forKey: .customColorAlpha)
        }
        
        if let imageName = backgroundImageName {
            try container.encode(imageName, forKey: .backgroundImageName)
        }
        
        if let widgetType = topWidgetType {
            try container.encode(widgetType, forKey: .topWidgetType)
        }
        try container.encode(fontSpacing, forKey: .fontSpacing)
    }
    
    /// 获取实际应用的颜色
    var actualFontColor: Color {
        if fontColor == .custom, let rgb = customColorRGB {
            return Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
        }
        return fontColor.color
    }
    
    // 实现 Equatable 协议
    static func == (lhs: FontSetting, rhs: FontSetting) -> Bool {
        guard lhs.fontSize == rhs.fontSize,
              lhs.customFont == rhs.customFont,
              lhs.fontColor == rhs.fontColor,
              lhs.customFontSize == rhs.customFontSize,
              lhs.backgroundImageName == rhs.backgroundImageName,
              lhs.topWidgetType == rhs.topWidgetType,
              lhs.fontSpacing == rhs.fontSpacing else {
            return false
        }
        
        // 比较自定义颜色 RGB 值
        switch (lhs.customColorRGB, rhs.customColorRGB) {
        case (nil, nil):
            return true
        case (let lhsRGB?, let rhsRGB?):
            return lhsRGB.red == rhsRGB.red &&
                   lhsRGB.green == rhsRGB.green &&
                   lhsRGB.blue == rhsRGB.blue &&
                   lhsRGB.alpha == rhsRGB.alpha
        default:
            return false
        }
    }
}

/// 字体大小枚举（保留以兼容已存储的 FontSetting JSON）
enum FontSize: String, CaseIterable, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case extraLarge = "extraLarge"
    case custom = "custom"
}

/// 字体颜色枚举
enum FontColor: String, CaseIterable, Codable {
    case white = "white"
    case black = "black"
    case custom = "custom"
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
    case yellow = "yellow"
    case pink = "pink"
    case cyan = "cyan"
    case mint = "mint"
    case indigo = "indigo"
    case teal = "teal"
    case brown = "brown"
    case gray = "gray"
    
    var displayName: String {
        switch self {
        case .white: return "白色"
        case .black: return "黑色"
        case .custom: return "自定义"
        case .blue: return "蓝色"
        case .green: return "绿色"
        case .orange: return "橙色"
        case .red: return "红色"
        case .purple: return "紫色"
        case .yellow: return "黄色"
        case .pink: return "粉色"
        case .cyan: return "青色"
        case .mint: return "薄荷绿"
        case .indigo: return "靛蓝"
        case .teal: return "蓝绿"
        case .brown: return "棕色"
        case .gray: return "灰色"
        }
    }
    
    var color: Color {
        switch self {
        case .white: return .white
        case .black: return .black
        case .custom: return .white  // 自定义颜色需要从 FontSetting 中获取
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .yellow: return .yellow
        case .pink: return .pink
        case .cyan: return .cyan
        case .mint: return .mint
        case .indigo: return .indigo
        case .teal: return .teal
        case .brown: return .brown
        case .gray: return .gray
        }
    }
}

// MARK: - WeatherKit 缓存（主 App + Widget 共用，TTL 内不重复请求）

enum WeatherCache {
    static let suiteName = AppGroupStore.suiteName
    static let temperatureKey = "weatherTemperature"
    static let symbolKey = "weatherConditionSymbol"
    static let fetchedAtKey = "weatherFetchedAt_v5"
    static let lastManualRefreshKey = "weatherLastManualRefresh_v1"
    static let locationLatitudeKey = "weatherLocationLatitude"
    static let locationLongitudeKey = "weatherLocationLongitude"
    static let locationNameKey = "weatherLocationName"
    static let usedFallbackLocationKey = "weatherUsedFallbackLocation"

    /// 缓存有效期：1 小时内不重复打 WeatherKit
    static let ttl: TimeInterval = 60 * 60
    /// 用户手动刷新冷却：2 分钟内不重复打 API
    static let manualCooldown: TimeInterval = 2 * 60

    struct Snapshot {
        let temperature: Double
        let symbol: String
        let fetchedAt: Date
        let locationName: String?
        let usedFallbackLocation: Bool

        var expiresAt: Date {
            fetchedAt.addingTimeInterval(WeatherCache.ttl)
        }

        /// 仅真实定位天气可用于展示（排除历史上的北京回退）
        var isUsable: Bool { !usedFallbackLocation }
    }

    enum ManualRefreshResult {
        case success(Snapshot)
        case cooldown(remaining: TimeInterval)
        case failed
    }

    static func load(from defaults: UserDefaults? = AppGroupStore.defaults) -> Snapshot? {
        guard let defaults,
              let temperature = defaults.object(forKey: temperatureKey) as? Double,
              let symbol = defaults.string(forKey: symbolKey),
              defaults.object(forKey: fetchedAtKey) != nil else {
            return nil
        }
        let fetchedAt = Date(timeIntervalSince1970: defaults.double(forKey: fetchedAtKey))
        return Snapshot(
            temperature: temperature,
            symbol: symbol,
            fetchedAt: fetchedAt,
            locationName: defaults.string(forKey: locationNameKey),
            usedFallbackLocation: defaults.bool(forKey: usedFallbackLocationKey)
        )
    }

    /// 可供 UI / 小组件展示的天气（不含默认城市回退）
    static func usableSnapshot(from defaults: UserDefaults? = AppGroupStore.defaults) -> Snapshot? {
        guard let snapshot = load(from: defaults), snapshot.isUsable else { return nil }
        return snapshot
    }

    static func isFresh(_ snapshot: Snapshot?, now: Date = Date()) -> Bool {
        guard let snapshot else { return false }
        return now.timeIntervalSince(snapshot.fetchedAt) < ttl
    }

    static func save(temperature: Double, symbol: String, at date: Date = Date()) {
        AppGroupStore.set(temperature, forKey: temperatureKey)
        AppGroupStore.set(symbol, forKey: symbolKey)
        AppGroupStore.set(date.timeIntervalSince1970, forKey: fetchedAtKey)
    }

    static func loadCachedLocation() -> CLLocation? {
        guard AppGroupStore.object(forKey: locationLatitudeKey) != nil,
              AppGroupStore.object(forKey: locationLongitudeKey) != nil else {
            return nil
        }
        return CLLocation(
            latitude: AppGroupStore.double(forKey: locationLatitudeKey),
            longitude: AppGroupStore.double(forKey: locationLongitudeKey)
        )
    }

    static func saveCachedLocation(_ location: CLLocation) {
        AppGroupStore.set(location.coordinate.latitude, forKey: locationLatitudeKey)
        AppGroupStore.set(location.coordinate.longitude, forKey: locationLongitudeKey)
    }

    static func loadCachedLocationName() -> String? {
        AppGroupStore.string(forKey: locationNameKey)
    }

    static func saveCachedLocationName(_ name: String?) {
        AppGroupStore.set(name, forKey: locationNameKey)
    }

    static func usedFallbackLocation() -> Bool {
        AppGroupStore.defaults?.bool(forKey: usedFallbackLocationKey) ?? false
    }

    private static func setUsedFallbackLocation(_ value: Bool) {
        AppGroupStore.set(value, forKey: usedFallbackLocationKey)
    }

    /// 清除历史上的默认城市（北京）回退数据，避免误展示
    static func clearFallbackCacheIfNeeded() {
        guard usedFallbackLocation() else { return }
        AppGroupStore.set(nil, forKey: temperatureKey)
        AppGroupStore.set(nil, forKey: symbolKey)
        AppGroupStore.set(nil, forKey: fetchedAtKey)
        AppGroupStore.set(nil, forKey: locationLatitudeKey)
        AppGroupStore.set(nil, forKey: locationLongitudeKey)
        AppGroupStore.set(nil, forKey: locationNameKey)
        setUsedFallbackLocation(false)
    }

    /// 优先设备定位（仅主 App）→ App Group 真实坐标缓存。无定位则返回 nil（不再回退北京）。
    /// Widget 扩展不现场定位，避免 requestLocation 挂起导致 timeline 不完成、桌面不刷新。
    static func resolveLocation() async -> CLLocation? {
        clearFallbackCacheIfNeeded()

        let runningInExtension = Bundle.main.bundleURL.pathExtension == "appex"
        if !runningInExtension {
            if let live = await WeatherLocationRequester.shared.requestIfPossible() {
                saveCachedLocation(live)
                setUsedFallbackLocation(false)
                return live
            }
            // 首次冷启动时系统可能暂时拿不到定位；无缓存时补一次短重试。
            if loadCachedLocation() == nil {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                if let retry = await WeatherLocationRequester.shared.requestIfPossible() {
                    saveCachedLocation(retry)
                    setUsedFallbackLocation(false)
                    return retry
                }
            }
        }
        if let cached = loadCachedLocation(), !usedFallbackLocation() {
            return cached
        }
        return nil
    }

    /// 缓存新鲜则直接返回；过期或不存在才请求 WeatherKit。失败时回退到旧「可用」缓存。
    static func refreshIfNeeded(now: Date = Date()) async -> Snapshot? {
        clearFallbackCacheIfNeeded()
        if let cached = usableSnapshot(),
           isFresh(cached, now: now),
           loadCachedLocation() != nil {
            return cached
        }
        return await fetchAndSave(now: now) ?? usableSnapshot()
    }

    /// 按最新定位强制拉取（不受 TTL / 手动冷却限制），用于首次选择天气等场景。
    static func refreshWithLatestLocation(now: Date = Date()) async -> Snapshot? {
        clearFallbackCacheIfNeeded()
        return await fetchAndSave(now: now) ?? usableSnapshot()
    }

    /// 用户主动刷新：绕过 TTL，但仍受手动冷却限制。
    static func forceRefresh(now: Date = Date()) async -> ManualRefreshResult {
        if let remaining = manualCooldownRemaining(now: now) {
            return .cooldown(remaining: remaining)
        }

        guard let snapshot = await fetchAndSave(now: now) else {
            return .failed
        }
        markManualRefresh(at: now)
        return .success(snapshot)
    }

    static func manualCooldownRemaining(now: Date = Date()) -> TimeInterval? {
        guard AppGroupStore.object(forKey: lastManualRefreshKey) != nil else {
            return nil
        }
        let last = Date(timeIntervalSince1970: AppGroupStore.double(forKey: lastManualRefreshKey))
        let elapsed = now.timeIntervalSince(last)
        guard elapsed < manualCooldown else { return nil }
        return manualCooldown - elapsed
    }

    private static func markManualRefresh(at date: Date) {
        AppGroupStore.set(date.timeIntervalSince1970, forKey: lastManualRefreshKey)
    }

    private static func fetchAndSave(now: Date) async -> Snapshot? {
        #if canImport(WeatherKit)
        if #available(iOS 16.0, *) {
            do {
                guard let location = await resolveLocation() else {
                    return nil
                }
                let weather = try await WeatherService.shared.weather(for: location)
                // 强制摄氏度，避免 locale 单位导致数值偏差
                let temperature = weather.currentWeather.temperature.converted(to: .celsius).value
                let symbol = weather.currentWeather.symbolName
                let locationName: String
                if let name = await reverseGeocodeCityName(for: location) {
                    locationName = name
                } else {
                    locationName = loadCachedLocationName() ?? "当前位置"
                }
                save(temperature: temperature, symbol: symbol, at: now)
                saveCachedLocationName(locationName)
                setUsedFallbackLocation(false)
                return Snapshot(
                    temperature: temperature,
                    symbol: symbol,
                    fetchedAt: now,
                    locationName: locationName,
                    usedFallbackLocation: false
                )
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    /// 逆地理编码，尽量得到「××市」一级名称。
    static func reverseGeocodeCityName(for location: CLLocation) async -> String? {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return nil }
            return preferredCityName(from: placemark)
        } catch {
            return nil
        }
    }

    static func preferredCityName(from placemark: CLPlacemark) -> String? {
        let locality = placemark.locality
        let admin = placemark.administrativeArea

        if let admin, admin.hasSuffix("市") {
            if let locality {
                if locality.hasSuffix("市") { return locality }
                if locality.hasSuffix("区") || locality.hasSuffix("县") || locality.hasSuffix("旗") {
                    return admin
                }
            }
            return admin
        }
        if let locality, !locality.isEmpty { return locality }
        if let admin, !admin.isEmpty { return admin }
        return placemark.name
    }

    /// 建议的下次刷新时间：优先对齐缓存过期点，并保证在未来。
    static func nextRefreshDate(after snapshot: Snapshot?, now: Date = Date()) -> Date {
        if let snapshot {
            let expiry = snapshot.expiresAt
            if expiry > now {
                return expiry
            }
        }
        return now.addingTimeInterval(ttl)
    }
}

/// 一次性定位；主 App 可弹授权，Widget 扩展仅在已授权时取一次位置。
private final class WeatherLocationRequester: NSObject, CLLocationManagerDelegate {
    static let shared = WeatherLocationRequester()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?
    private var timeoutWorkItem: DispatchWorkItem?

    private var isAppExtension: Bool {
        Bundle.main.bundleURL.pathExtension == "appex"
    }

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestIfPossible() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }
                // 避免并发请求互相覆盖
                if self.continuation != nil {
                    continuation.resume(returning: nil)
                    return
                }
                self.continuation = continuation

                // 不在主线程调 locationServicesEnabled()：会同步卡住 UI。
                // 系统关闭定位时，authorizationStatus / didFailWithError 会走到失败分支。
                switch self.manager.authorizationStatus {
                case .authorizedAlways, .authorizedWhenInUse:
                    if let lastKnown = self.recentLastKnownLocation(maxAge: 30 * 60) {
                        self.finish(lastKnown)
                    } else {
                        self.startLocationRequest(timeout: 12)
                    }
                case .notDetermined:
                    if self.isAppExtension {
                        self.finish(nil)
                    } else {
                        // 等用户点授权（不设过短超时，避免定位结果被丢弃）
                        self.armTimeout(seconds: 90)
                        self.manager.requestWhenInUseAuthorization()
                    }
                default:
                    self.finish(nil)
                }
            }
        }
    }

    private func startLocationRequest(timeout: TimeInterval) {
        armTimeout(seconds: timeout)
        manager.requestLocation()
    }

    private func armTimeout(seconds: TimeInterval) {
        timeoutWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.finish(nil)
        }
        timeoutWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func recentLastKnownLocation(maxAge: TimeInterval) -> CLLocation? {
        guard let location = manager.location else { return nil }
        let age = abs(location.timestamp.timeIntervalSinceNow)
        return age <= maxAge ? location : nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if continuation != nil {
                startLocationRequest(timeout: 10)
            } else if !isAppExtension {
                // 授权弹窗期间曾超时：仍取一次位置写入缓存，供下次天气使用
                manager.requestLocation()
            }
        case .denied, .restricted:
            finish(nil)
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        if let location {
            // 即便 continuation 已超时结束，也写入缓存，供下次天气使用
            WeatherCache.saveCachedLocation(location)
            WeatherCache.setUsedFallbackLocationForRequester(false)
        }
        finish(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(nil)
    }

    private func finish(_ location: CLLocation?) {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: location)
    }
}

extension WeatherLocationRequester: @unchecked Sendable {}

extension WeatherCache {
    /// 供定位回调写入；避免 requester 直接调 private setter 时的可见性问题。
    fileprivate static func setUsedFallbackLocationForRequester(_ value: Bool) {
        AppGroupStore.set(value, forKey: usedFallbackLocationKey)
    }
}
