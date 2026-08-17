//
//  WidgetViewView.swift
//  Min
//
//  个性化页顶部：桌面 Large Widget 预览（宽度与下方选项行一致）
//

import SwiftUI
import UIKit

struct WidgetViewView: View {
    let fontSetting: FontSetting
    let textAlignment: TextAlignmentView.TextAlignment

    /// 与桌面 Large Widget（group 1）同步：从共享容器读取
    @State private var groupItems: [WidgetItem] = []
    @State private var previewBackgroundImage: UIImage?

    var body: some View {
        // 正方形预览：左右与下方「背景 / 字体…」选项同宽（由 SettingView contentInset 控制）
        GeometryReader { geometry in
            let side = geometry.size.width
            ZStack {
                ZStack {
                    if let previewBackgroundImage {
                        Image(uiImage: previewBackgroundImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .clipped()
                    } else if let imageName = fontSetting.backgroundImageName,
                              let backgroundImage = WidgetImageManager.shared.loadImage(named: imageName) {
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: side, height: side)
                            .clipped()
                    } else {
                        Color.black
                    }
                }
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: MinSettingChrome.corner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: MinSettingChrome.corner, style: .continuous)
                        .stroke(MinSettingChrome.stroke, lineWidth: 0.5)
                )

                let refSide: CGFloat = 360
                let rowHeight: CGFloat = 50 * (side / refSide)
                let spacing: CGFloat = fontSetting.fontSpacing * 2 * (side / refSide)
                let verticalPadding: CGFloat = 8 + fontSetting.fontSpacing * 0.6
                VStack(spacing: spacing) {
                    if groupItems.isEmpty {
                        WidgetStyledText(
                            text: "无应用",
                            customFont: fontSetting.customFont,
                            size: fontSetting.customFontSize,
                            color: fontSetting.actualFontColor.opacity(0.5)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ForEach(groupItems) { item in
                            HStack {
                                WidgetStyledText(
                                    text: item.name,
                                    customFont: fontSetting.customFont,
                                    size: fontSetting.customFontSize,
                                    color: fontSetting.actualFontColor,
                                    maxWidth: side - 32
                                )
                                .frame(maxWidth: .infinity, alignment: textAlignment.asAlignment)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: rowHeight)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, verticalPadding)
                .frame(width: side, height: side)
                .id("\(fontSetting.customFont.customFontStorageFileName ?? fontSetting.customFont.customFontPostScriptName ?? fontSetting.customFont.fontName.rawValue)-\(fontSetting.customFontSize)-\(fontSetting.fontSpacing)")
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            reloadGroupItems()
            reloadPreviewBackground()
        }
        .onChange(of: fontSetting.backgroundImageName) { _, _ in
            reloadPreviewBackground()
        }
    }

    private func reloadGroupItems() {
        Task(priority: .userInitiated) {
            let data = WidgetData.loadFromSharedContainer()
            let items = data.items.filter { $0.group == 1 }.sorted { $0.order < $1.order }
            await MainActor.run {
                groupItems = items
            }
        }
    }

    private func reloadPreviewBackground() {
        guard let imageName = fontSetting.backgroundImageName else {
            previewBackgroundImage = nil
            return
        }
        Task(priority: .userInitiated) {
            try? await Task.sleep(nanoseconds: 50_000_000)

            let croppedName = "large_\(imageName)"
            let loaded = WidgetImageManager.shared.loadImage(named: croppedName)
                ?? WidgetImageManager.shared.loadImage(named: imageName)

            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    previewBackgroundImage = loaded
                }
            }
        }
    }
}

#Preview {
    WidgetViewView(
        fontSetting: FontSetting(),
        textAlignment: .leading
    )
    .preferredColorScheme(.dark)
}
