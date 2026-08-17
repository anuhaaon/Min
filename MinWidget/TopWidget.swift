//
//  TopWidget.swift
//  MinWidget
//
//  Created by dh on 2025/11/23.
//

import WidgetKit
import SwiftUI
import os.log
import UIKit

struct TopWidgetEntry: TimelineEntry {
    let date: Date
    let widgetType: TopWidgetType?
    let backgroundImageName: String?
    let fontSetting: FontSetting
    let textAlignment: TextAlignmentType
    /// 天气温度（仅当 widgetType == .weather 时有效）
    let weatherTemperature: Double?
    /// 天气状况对应的 SF Symbol 名称（仅当 widgetType == .weather 时有效）
    let weatherConditionSymbol: String?
    
    init(date: Date, widgetType: TopWidgetType?, backgroundImageName: String?, fontSetting: FontSetting, textAlignment: TextAlignmentType, weatherTemperature: Double? = nil, weatherConditionSymbol: String? = nil) {
        self.date = date
        self.widgetType = widgetType
        self.backgroundImageName = backgroundImageName
        self.fontSetting = fontSetting
        self.textAlignment = textAlignment
        self.weatherTemperature = weatherTemperature
        self.weatherConditionSymbol = weatherConditionSymbol
    }
}

struct TopWidgetProvider: TimelineProvider {
    private let logger = Logger(subsystem: "com.denghao.Min.MinWidget", category: "TopWidget")
    
    func placeholder(in context: Context) -> TopWidgetEntry {
        TopWidgetEntry(
            date: Date(),
            widgetType: .time,
            backgroundImageName: nil,
            fontSetting: FontSetting(),
            textAlignment: .center
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TopWidgetEntry) -> ()) {
        var widgetData = WidgetData.loadFromSharedContainer()
        prepareCustomFont(for: &widgetData)
        let widgetType = widgetData.fontSetting.topWidgetType
        var backgroundImageName = widgetData.fontSetting.backgroundImageName
        
        if let imageName = backgroundImageName {
            backgroundImageName = "top_\(imageName)"
        }
        
        logger.info("TopWidgetProvider.getSnapshot: widgetType = \(widgetType?.rawValue ?? "nil"), backgroundImageName = \(backgroundImageName ?? "nil")")
        print("TopWidgetProvider.getSnapshot: widgetType = \(widgetType?.rawValue ?? "nil"), backgroundImageName = \(backgroundImageName ?? "nil")")
        
        var weatherTemperature: Double? = nil
        var weatherConditionSymbol: String? = nil
        if widgetType == .weather {
            let cached = WeatherCache.usableSnapshot()
            weatherTemperature = cached?.temperature
            weatherConditionSymbol = cached?.symbol
        }
        let entry = TopWidgetEntry(
            date: Date(),
            widgetType: widgetType,
            backgroundImageName: backgroundImageName,
            fontSetting: widgetData.fontSetting,
            textAlignment: widgetData.textAlignment,
            weatherTemperature: weatherTemperature,
            weatherConditionSymbol: weatherConditionSymbol
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        var widgetData = WidgetData.loadFromSharedContainer()
        prepareCustomFont(for: &widgetData)
        let widgetType = widgetData.fontSetting.topWidgetType
        var backgroundImageName = widgetData.fontSetting.backgroundImageName
        
        logger.info("TopWidgetProvider.getTimeline: widgetType = \(widgetType?.rawValue ?? "nil"), backgroundImageName = \(backgroundImageName ?? "nil")")
        print("TopWidgetProvider.getTimeline: widgetType = \(widgetType?.rawValue ?? "nil"), backgroundImageName = \(backgroundImageName ?? "nil")")

        if let imageName = backgroundImageName {
            backgroundImageName = "top_\(imageName)"
        }
        
        // 天气：仅展示真实定位缓存；无可用定位时留白，短间隔再试（不回退默认城市）
        if widgetType == .weather {
            WeatherCache.clearFallbackCacheIfNeeded()
            let cached = WeatherCache.usableSnapshot()
            if WeatherCache.isFresh(cached, now: currentDate) {
                let weatherEntry = TopWidgetEntry(
                    date: currentDate,
                    widgetType: widgetType,
                    backgroundImageName: backgroundImageName,
                    fontSetting: widgetData.fontSetting,
                    textAlignment: widgetData.textAlignment,
                    weatherTemperature: cached?.temperature,
                    weatherConditionSymbol: cached?.symbol
                )
                let nextUpdate = WeatherCache.nextRefreshDate(after: cached, now: currentDate)
                completion(Timeline(entries: [weatherEntry], policy: .after(nextUpdate)))
                return
            }

            Task {
                let snapshot = await WeatherCache.refreshIfNeeded(now: currentDate)
                if snapshot == nil {
                    logger.info("TopWidgetProvider.getTimeline: 尚无真实定位天气")
                }
                let weatherEntry = TopWidgetEntry(
                    date: currentDate,
                    widgetType: widgetType,
                    backgroundImageName: backgroundImageName,
                    fontSetting: widgetData.fontSetting,
                    textAlignment: widgetData.textAlignment,
                    weatherTemperature: snapshot?.temperature,
                    weatherConditionSymbol: snapshot?.symbol
                )
                // 无可用天气时尽快再试；有缓存则对齐 TTL
                let nextUpdate = snapshot == nil
                    ? currentDate.addingTimeInterval(60)
                    : WeatherCache.nextRefreshDate(after: snapshot, now: currentDate)
                completion(Timeline(entries: [weatherEntry], policy: .after(nextUpdate)))
            }
            return
        }
        
        let entry = TopWidgetEntry(
            date: currentDate,
            widgetType: widgetType,
            backgroundImageName: backgroundImageName,
            fontSetting: widgetData.fontSetting,
            textAlignment: widgetData.textAlignment
        )
        
        // 根据 widget 类型决定更新策略
        // 为了确保设置更改后能立即刷新，我们创建多个 entry
        var entries: [TopWidgetEntry] = [entry]
        
        let nextUpdate: Date
        if widgetType == .time {
            // 时间 widget：每分钟更新一次
            nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
        } else {
            // 日期 widget 或 nil：需要更频繁的更新以确保 widgetType 和背景图片更改后能立即刷新
            // 创建多个短期 entry 以确保立即刷新
            let shortTermUpdate1 = Calendar.current.date(byAdding: .second, value: 10, to: currentDate)!
            let shortTermUpdate2 = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)!
            
            // 添加短期 entries 以确保设置更改后能快速刷新
            // 重新加载数据以确保获取最新的 widgetType 和背景图片名称
            let shortTermWidgetData1 = WidgetData.loadFromSharedContainer()
            var shortTermBackgroundImageName1 = shortTermWidgetData1.fontSetting.backgroundImageName
            if let imageName = shortTermBackgroundImageName1 {
                shortTermBackgroundImageName1 = "top_\(imageName)"
            }
            let shortTermEntry1 = TopWidgetEntry(
                date: shortTermUpdate1,
                widgetType: shortTermWidgetData1.fontSetting.topWidgetType,
                backgroundImageName: shortTermBackgroundImageName1,
                fontSetting: shortTermWidgetData1.fontSetting,
                textAlignment: shortTermWidgetData1.textAlignment
            )
            entries.append(shortTermEntry1)
            
            let shortTermWidgetData2 = WidgetData.loadFromSharedContainer()
            var shortTermBackgroundImageName2 = shortTermWidgetData2.fontSetting.backgroundImageName
            if let imageName = shortTermBackgroundImageName2 {
                shortTermBackgroundImageName2 = "top_\(imageName)"
            }
            let shortTermEntry2 = TopWidgetEntry(
                date: shortTermUpdate2,
                widgetType: shortTermWidgetData2.fontSetting.topWidgetType,
                backgroundImageName: shortTermBackgroundImageName2,
                fontSetting: shortTermWidgetData2.fontSetting,
                textAlignment: shortTermWidgetData2.textAlignment
            )
            entries.append(shortTermEntry2)
            
            // 对于日期 widget，使用1分钟的更新间隔
            nextUpdate = shortTermUpdate2
        }
        
        // 使用 .after 策略，但配合 reloadTimelines 调用，确保设置更改后能立即刷新
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func prepareCustomFont(for widgetData: inout WidgetData) {
        let cf = widgetData.fontSetting.customFont
        print("TopWidget.prepareCustomFont: storage=\(cf.customFontStorageFileName ?? "nil") ps=\(cf.customFontPostScriptName ?? "nil")")
        if let storage = cf.customFontStorageFileName, !storage.isEmpty {
            if let resolved = AppGroupFontRegistrar.registerStorageFileName(storage) {
                widgetData.fontSetting.customFont.customFontPostScriptName = resolved
                print("TopWidget.prepareCustomFont: 注册成功 → \(resolved)")
            } else {
                print("TopWidget.prepareCustomFont: 注册失败 storage=\(storage)")
            }
            return
        }
        guard let name = cf.customFontPostScriptName, !name.isEmpty else { return }
        if UIFont(name: name, size: 12) != nil { return }
        if let item = ODRFontCatalog.all.first(where: { $0.postScriptName == name }) {
            if let resolved = AppGroupFontRegistrar.registerStorageFileName(item.storageFileName) {
                widgetData.fontSetting.customFont.customFontPostScriptName = resolved
                widgetData.fontSetting.customFont.customFontStorageFileName = item.storageFileName
            }
            return
        }
        if let resolved = AppGroupFontRegistrar.registerIfNeeded(preferringPostScriptName: name) {
            widgetData.fontSetting.customFont.customFontPostScriptName = resolved
        }
    }
}

struct TopWidgetEntryView: View {
    var entry: TopWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var useHighContrastRendering: Bool {
        if #available(iOSApplicationExtension 18.0, *) {
            // iOS 26 桌面自定义「透明 / 色调」都会进入非 fullColor 渲染
            // 统一启用高对比方案，避免背景与文字被系统一并漂白
            return renderingMode != .fullColor
        }
        return false
    }

    private var widgetTextColor: Color {
        useHighContrastRendering ? .white : entry.fontSetting.actualFontColor
    }
    
    private var contentHorizontalPadding: CGFloat {
        switch entry.textAlignment {
        case .leading, .trailing:
            return 30
        case .center:
            return 16
        }
    }

    private var timeString: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: entry.date)
    }
    
    private var dateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter.string(from: entry.date)
    }

    var body: some View {
        ZStack {
            backgroundView
            contentView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(for: .widget) {
            useHighContrastRendering ? Color.black : Color.clear
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch entry.widgetType {
        case .empty:
            EmptyView()
        case .weather:
            // 尚无真实定位天气时留白；有数据再显示
            if entry.weatherTemperature != nil {
                if let refreshURL = URL(string: "min://weather") {
                    Link(destination: refreshURL) {
                        weatherContentView
                    }
                } else {
                    weatherContentView
                }
            } else {
                EmptyView()
            }
        default:
            WidgetStyledText(
                text: displayString,
                customFont: entry.fontSetting.customFont,
                size: entry.fontSetting.customFontSize,
                color: widgetTextColor,
                asyncRender: false
            )
            .frame(maxWidth: .infinity, alignment: entry.textAlignment.asAlignment)
            .padding(.horizontal, contentHorizontalPadding)
        }
    }
    
    private var weatherContentView: some View {
        let symbolName = entry.weatherConditionSymbol ?? "cloud.sun.fill"
        let tempText = entry.weatherTemperature.map { "\(Int($0.rounded()))°" } ?? "--°"
        let size = entry.fontSetting.customFontSize
        let hAlign: HorizontalAlignment
        switch entry.textAlignment {
        case .center: hAlign = .center
        case .trailing: hAlign = .trailing
        default: hAlign = .leading
        }
        return VStack(alignment: hAlign, spacing: 0) {
            Spacer(minLength: 0)
            Image(systemName: symbolName)
                .font(.system(size: size * 0.78, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .foregroundColor(widgetTextColor)
            Spacer(minLength: 0)
            WidgetStyledText(
                text: tempText,
                customFont: entry.fontSetting.customFont,
                size: size * 0.72,
                color: widgetTextColor,
                tracking: 0.5,
                asyncRender: false
            )
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: entry.textAlignment.asAlignment)
        .padding(.horizontal, contentHorizontalPadding)
    }

    private var displayString: String {
        if let widgetType = entry.widgetType, widgetType == .date {
            return dateString
        }
        return timeString
    }
    
    // 背景视图（计算属性）
    @ViewBuilder
    private var backgroundView: some View {
        Group {
            if useHighContrastRendering {
                Color.black
            } else if let imageName = entry.backgroundImageName,
                      let backgroundImage = WidgetImageManager.shared.loadImage(named: imageName) {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Color.black
            }
        }
    }
}

struct MinTopWidget: Widget {
    let kind: String = "MinTopWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TopWidgetProvider()) { entry in
            TopWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
        .configurationDisplayName("顶部小组件")
        .description("显示时间、日期、空白或当天天气")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    MinTopWidget()
} timeline: {
    TopWidgetEntry(date: Date(), widgetType: .time, backgroundImageName: nil, fontSetting: FontSetting(), textAlignment: .center)
    TopWidgetEntry(date: Date(), widgetType: .date, backgroundImageName: nil, fontSetting: FontSetting(), textAlignment: .center)
    TopWidgetEntry(date: Date(), widgetType: .empty, backgroundImageName: nil, fontSetting: FontSetting(), textAlignment: .center)
    TopWidgetEntry(date: Date(), widgetType: .weather, backgroundImageName: nil, fontSetting: FontSetting(), textAlignment: .center, weatherTemperature: 25, weatherConditionSymbol: "cloud.sun.fill")
}

