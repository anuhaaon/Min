//
//  TopWidgetView.swift
//  Min
//
//  Created by dh on 2025/11/23.
//

import SwiftUI
import WidgetKit
#if canImport(UIKit)
import UIKit
#endif

struct TopWidgetView: View {
    @Binding var fontSetting: FontSetting
    @State private var showWidgetSheet = false
    
    private let haptic = HapticFeedbackHelper.shared
    
    var body: some View {
        ZStack(alignment: .leading) {
            MinSettingChrome.rowBackground()
                .frame(height: MinSettingChrome.rowHeight)
            
            HStack(spacing: 0) {
                Image(systemName: "square.on.square")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.leading, 28)
                
                Text("顶部小组件")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 10)
                
                Spacer(minLength: 8)
                
                Button {
                    haptic.light()
                    showWidgetSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Text(fontSetting.topWidgetType?.displayName ?? TopWidgetType.empty.displayName)
                            .font(.system(size: 12))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: MinSettingChrome.chipCorner, style: .continuous).fill(Color.gray.opacity(0.3)))
                }
                .padding(.trailing, 28)
            }
            .frame(height: MinSettingChrome.rowHeight)
        }
        .sheet(isPresented: $showWidgetSheet) {
            TopWidgetSelectionView(fontSetting: $fontSetting)
                .minNativeSheet(detents: [.height(TopWidgetSelectionView.preferredSheetHeight)])
        }
    }
}

struct TopWidgetSelectionView: View {
    @Binding var fontSetting: FontSetting
    @EnvironmentObject private var subscription: SubscriptionManager

    /// sheet 顶 → 标题、标题 → 选项、天气 → sheet 底，三处等距
    private static let chromeGap = MinSettingChrome.sheetChromeGap
    private static let cardSpacing: CGFloat = 12
    /// 单卡约 80 预览 + 上下 padding 16×2
    private static let cardHeight: CGFloat = 112
    private static let titleHeight: CGFloat = 22
    /// 内容高度（不含系统拖拽条安全区，系统会再叠加）
    static var preferredSheetHeight: CGFloat {
        chromeGap // 顶 → 标题
        + titleHeight
        + chromeGap // 标题 → 选项
        + cardHeight * 4
        + cardSpacing * 3
        + chromeGap // 天气 → 底
    }

    @State private var resolvedCityName: String? = Self.cachedCityName()
    @State private var isResolvingLocation = false
    @State private var showPaywall = false

    private static func cachedCityName() -> String? {
        WeatherCache.clearFallbackCacheIfNeeded()
        return WeatherCache.usableSnapshot()?.locationName
            ?? (WeatherCache.usedFallbackLocation() ? nil : WeatherCache.loadCachedLocationName())
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("顶部小组件类型")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.top, Self.chromeGap)
                .padding(.bottom, Self.chromeGap)

            VStack(spacing: Self.cardSpacing) {
                WidgetOptionCard(
                    title: "空白",
                    widgetKind: "MinTopWidget",
                    isSelected: fontSetting.topWidgetType == .empty,
                    isLocked: false,
                    preview: {
                        ZStack {
                            Color(white: 0.18)
                            Text("-")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    },
                    description: {
                        Text("无内容，仅保留背景")
                    },
                    onSelect: {
                        fontSetting.topWidgetType = .empty
                        HapticFeedbackHelper.shared.selection()
                        saveFontSettingToSharedContainer()
                    }
                )

                WidgetOptionCard(
                    title: "时间",
                    widgetKind: "MinTopWidget",
                    isSelected: fontSetting.topWidgetType == .time,
                    isLocked: false,
                    preview: {
                        VStack {
                            Text("16:48")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(white: 0.18))
                    },
                    description: {
                        Text("显示当前时间")
                    },
                    onSelect: {
                        fontSetting.topWidgetType = .time
                        HapticFeedbackHelper.shared.selection()
                        saveFontSettingToSharedContainer()
                    }
                )

                WidgetOptionCard(
                    title: "日期",
                    widgetKind: "MinTopWidget",
                    isSelected: fontSetting.topWidgetType == .date,
                    isLocked: false,
                    preview: {
                        VStack {
                            Text("Jun 8")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(white: 0.18))
                    },
                    description: {
                        Text("显示当前日期")
                    },
                    onSelect: {
                        fontSetting.topWidgetType = .date
                        HapticFeedbackHelper.shared.selection()
                        saveFontSettingToSharedContainer()
                    }
                )

                WidgetOptionCard(
                    title: "天气",
                    widgetKind: "MinTopWidget",
                    isSelected: fontSetting.topWidgetType == .weather,
                    isLocked: !subscription.canUseWeatherWidget,
                    preview: {
                        weatherPreview
                    },
                    description: {
                        if subscription.canUseWeatherWidget {
                            weatherDescription
                        } else {
                            Text("Pro 解锁天气小组件")
                        }
                    },
                    onSelect: {
                        guard subscription.canUseWeatherWidget else {
                            HapticFeedbackHelper.shared.light()
                            showPaywall = true
                            return
                        }
                        fontSetting.topWidgetType = .weather
                        HapticFeedbackHelper.shared.selection()
                        saveFontSettingToSharedContainer()
                        Task {
                            await refreshLocationWeather(force: true)
                        }
                    }
                )
            }
            .padding(.horizontal, MinSettingChrome.contentInset)
            .padding(.bottom, Self.chromeGap)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
        .preferredColorScheme(.dark)
        .task {
            // 仅用于右侧城市文案；左侧预览为固定示意，不依赖实时天气
            await refreshLocationWeather(force: resolvedCityName == nil)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscription)
                .minNativeSheet(detents: [.large])
        }
    }

    /// 选项卡左侧固定示意，避免无缓存时一直转圈
    private var weatherPreview: some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Text("16°")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.18))
    }

    @ViewBuilder
    private var weatherDescription: some View {
        if let city = resolvedCityName, !city.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(city)
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.4))
        } else {
            ProgressView()
                .controlSize(.mini)
                .tint(.white.opacity(0.45))
        }
    }

    /// 拉取真实定位天气；失败则保持加载态并短间隔重试。
    private func refreshLocationWeather(force: Bool) async {
        if isResolvingLocation { return }
        if !force, resolvedCityName != nil, WeatherCache.usableSnapshot() != nil { return }

        await MainActor.run {
            isResolvingLocation = true
            if resolvedCityName == nil {
                // 保持加载 UI
            }
        }

        let snapshot = force
            ? await WeatherCache.refreshWithLatestLocation()
            : await WeatherCache.refreshIfNeeded()

        await MainActor.run {
            if let name = snapshot?.locationName, !name.isEmpty {
                resolvedCityName = name
            } else if let name = Self.cachedCityName() {
                resolvedCityName = name
            }
            isResolvingLocation = false
            WidgetCenter.shared.reloadTimelines(ofKind: "MinTopWidget")
        }

        // 仍无可用定位：继续重试，直到拿到城市（sheet 关闭时 task 取消）
        if WeatherCache.usableSnapshot() == nil {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            await refreshLocationWeather(force: true)
        }
    }
}

struct WidgetOptionCard<Preview: View, Description: View>: View {
    let title: String
    let widgetKind: String
    let isSelected: Bool
    var isLocked: Bool = false
    @ViewBuilder let preview: () -> Preview
    @ViewBuilder let description: () -> Description
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 16) {
                // 预览
                preview()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: MinSettingChrome.chipCorner + 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: MinSettingChrome.chipCorner + 4, style: .continuous)
                            .stroke(
                                isSelected ? Color.white.opacity(0.55) : Color.white.opacity(0.12),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                    .opacity(isLocked ? 0.55 : 1)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                        if isLocked {
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.6)
                                .foregroundStyle(.white.opacity(0.55))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color.white.opacity(0.10))
                                )
                        }
                    }
                    
                    description()
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                
                Spacer()
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.black, Color.white.opacity(0.85))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.28))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: MinSettingChrome.corner, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: MinSettingChrome.corner, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.18) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}

extension TopWidgetSelectionView {
    // 保存字体设置到共享容器并刷新 widget
    private func saveFontSettingToSharedContainer() {
        let encoder = JSONEncoder()
        do {
            let fontSettingData = try encoder.encode(fontSetting)
            AppGroupStore.set(fontSettingData, forKey: "fontSetting")
            AppGroupStore.reloadWidgetsDebounced()
        } catch {
            print("TopWidgetSelectionView: 保存字体设置失败: \(error)")
        }
    }
}

#Preview {
    TopWidgetView(fontSetting: .constant(FontSetting()))
        .environmentObject(SubscriptionManager.shared)
        .preferredColorScheme(.dark)
}
