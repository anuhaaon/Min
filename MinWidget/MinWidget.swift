//
//  MinWidget.swift
//  MinWidget
//
//  Created by dh on 2025/3/8.
//

import WidgetKit
import SwiftUI
import UIKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), widgetData: WidgetData(items: []))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        var widgetData = WidgetData.loadFromSharedContainer()
        prepareCustomFont(for: &widgetData)
        if let imageName = widgetData.fontSetting.backgroundImageName {
            widgetData.fontSetting.backgroundImageName = "large_\(imageName)"
        }
        let entry = SimpleEntry(date: Date(), widgetData: widgetData)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var widgetData = WidgetData.loadFromSharedContainer()
        prepareCustomFont(for: &widgetData)

        if let imageName = widgetData.fontSetting.backgroundImageName {
            widgetData.fontSetting.backgroundImageName = "large_\(imageName)"
        }
        
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, widgetData: widgetData)
        
        // 减少刷新时间，从15分钟改为5分钟；兜底避免极端情况下返回 nil
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)
            ?? currentDate.addingTimeInterval(5 * 60)
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        
        completion(timeline)
    }

    /// 在出图前注册 App Group 字体，并用真实 PostScript 名替换
    private func prepareCustomFont(for widgetData: inout WidgetData) {
        let cf = widgetData.fontSetting.customFont
        if let storage = cf.customFontStorageFileName, !storage.isEmpty {
            if let resolved = AppGroupFontRegistrar.registerStorageFileName(storage) {
                widgetData.fontSetting.customFont.customFontPostScriptName = resolved
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

struct SimpleEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

struct MinWidgetEntryView : View {
    var entry: Provider.Entry
    var group: Int
    @Environment(\.widgetFamily) private var widgetFamily  //只允许大号小组件
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var useHighContrastRendering: Bool {
        if #available(iOSApplicationExtension 18.0, *) {
            // iOS 26 桌面自定义「透明 / 色调」都会进入非 fullColor 渲染
            // 统一启用高对比方案，避免背景与文字被系统一并漂白
            return renderingMode != .fullColor
        }
        return false
    }

    var body: some View {
        ZStack {
            if useHighContrastRendering {
                Color.black
            } else if let imageName = entry.widgetData.fontSetting.backgroundImageName,
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
            
            GroupWidgetView(
                group: group,
                items: entry.widgetData.items,
                fontSetting: entry.widgetData.fontSetting,
                textAlignment: entry.widgetData.textAlignment,
                useHighContrastRendering: useHighContrastRendering
            )
        }
        .containerBackground(for: .widget) {
            useHighContrastRendering ? Color.black : Color.clear
        }
    }
}

// View for a specific group
struct GroupWidgetView: View {
    let group: Int
    let items: [WidgetItem]
    
    let fontSetting: FontSetting
    let textAlignment: TextAlignmentType
    let useHighContrastRendering: Bool
    
    @Environment(\.widgetFamily) private var family
    
    private var contentHorizontalPadding: CGFloat {
        switch textAlignment {
        case .leading, .trailing:
            return 30
        case .center:
            return 16
        }
    }
    
    private var groupItems: [WidgetItem] {
        return items.filter { $0.group == group }
            .sorted { $0.order < $1.order }
    }

    private var widgetTextColor: Color {
        useHighContrastRendering ? .white : fontSetting.actualFontColor
    }
    
    var body: some View {
        if groupItems.isEmpty {
            WidgetStyledText(
                text: "无应用",
                customFont: fontSetting.customFont,
                size: fontSetting.customFontSize,
                color: widgetTextColor.opacity(0.5),
                asyncRender: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: textAlignment.asAlignment)
            .padding(.horizontal, contentHorizontalPadding)
        } else {
            // 设置 0–20 对应实际 0–40pt，桌面小组件里间距更明显
            let spacing = fontSetting.fontSpacing * 2
            VStack(spacing: spacing) {
                ForEach(groupItems) { item in
                    if let finalURL = URL(string: item.url) {
                        Link(destination: finalURL) {
                            GeometryReader { geo in
                                WidgetStyledText(
                                    text: item.name,
                                    customFont: fontSetting.customFont,
                                    size: fontSetting.customFontSize,
                                    color: widgetTextColor,
                                    maxWidth: geo.size.width,
                                    asyncRender: false
                                )
                                .frame(width: geo.size.width, height: geo.size.height, alignment: textAlignment.asAlignment)
                            }
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, contentHorizontalPadding)
        }
    }
}



// Widget for Group 1
struct MinWidgetGroup1: Widget {
    let kind: String = "MinWidgetGroup1"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MinWidgetEntryView(entry: entry, group: 1)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
        .configurationDisplayName("分组 1")
        .description("第 1 组应用快捷方式")
        .supportedFamilies([.systemLarge])
    }
}

// Widget for Group 2
struct MinWidgetGroup2: Widget {
    let kind: String = "MinWidgetGroup2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MinWidgetEntryView(entry: entry, group: 2)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
        .configurationDisplayName("分组 2")
        .description("第 2 组应用快捷方式")
        .supportedFamilies([.systemLarge])
    }
}

// Widget for Group 3
struct MinWidgetGroup3: Widget {
    let kind: String = "MinWidgetGroup3"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            
            MinWidgetEntryView(entry: entry, group: 3)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
        .configurationDisplayName("分组 3")
        .description("第 3 组应用快捷方式")
        .supportedFamilies([.systemLarge])
    }
}

// Widget for Group 4
struct MinWidgetGroup4: Widget {
    let kind: String = "MinWidgetGroup4"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MinWidgetEntryView(entry: entry, group: 4)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
        .configurationDisplayName("分组 4")
        .description("第 4 组应用快捷方式")
        .supportedFamilies([.systemLarge])
    }
}

#Preview(as: .systemLarge) {
    MinWidgetGroup1()
} timeline: {
    let mockItems = [
        WidgetItem(id: UUID(), name: "微信", url: "weixin://", order: 0, group: 1),
        WidgetItem(id: UUID(), name: "支付宝", url: "alipay://", order: 1, group: 1),
        WidgetItem(id: UUID(), name: "淘宝", url: "taobao://", order: 2, group: 1),
        WidgetItem(id: UUID(), name: "地图", url: "alipay://", order: 3, group: 1),
        WidgetItem(id: UUID(), name: "信息", url: "taobao://", order: 4, group: 1)
    ]
    
    SimpleEntry(
        date: Date(),
        widgetData: WidgetData(items: mockItems, fontSetting: FontSetting(), textAlignment: .leading)
    )
}
