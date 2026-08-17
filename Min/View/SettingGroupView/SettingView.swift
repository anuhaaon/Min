//
//  SettingView.swift
//  Min
//
//  Created by dh on 2025/6/9.
//

import SwiftUI

struct SettingView: View {
    
    @Binding var selectedAlignment: TextAlignmentView.TextAlignment
    @Binding var fontSetting: FontSetting
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: MinSettingChrome.sectionSpacing) {
                    WidgetViewView(fontSetting: fontSetting, textAlignment: selectedAlignment)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        SettingSectionHeader(title: "主题")
                        VStack(spacing: MinSettingChrome.rowSpacing) {
                            CustomWallpaperView(fontSetting: $fontSetting)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        SettingSectionHeader(title: "字体")
                        VStack(spacing: MinSettingChrome.rowSpacing) {
                            TextAlignmentView(selectedAlignment: $selectedAlignment)
                            FontFamilyView(customFont: $fontSetting.customFont)
                            FontSizeView(fontSetting: $fontSetting)
                            FontSpacingView(fontSetting: $fontSetting)
                            FontColorView(fontSetting: $fontSetting)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        SettingSectionHeader(title: "小组件")
                        VStack(spacing: MinSettingChrome.rowSpacing) {
                            TopWidgetView(fontSetting: $fontSetting)
                        }
                    }
                }
                .padding(.horizontal, MinSettingChrome.contentInset)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            // iOS 26：系统 Scroll Edge Effect（Liquid Glass 柔和过渡），替代手写黑渐变
            .modifier(MinSoftScrollEdges())
        }
        .preferredColorScheme(.dark)
    }
}

/// 优先使用系统 scrollEdgeEffectStyle；低版本不做假渐变（纯黑底已足够自然）
private struct MinSoftScrollEdges: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .scrollEdgeEffectStyle(.soft, for: .top)
                .scrollEdgeEffectStyle(.soft, for: .bottom)
        } else {
            content
        }
    }
}

/// 分组标题（主题 / 字体 / 小组件）
private struct SettingSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.leading, 4)
    }
}

#Preview {
    SettingView(
        selectedAlignment: .constant(.leading),
        fontSetting: .constant(FontSetting())
    )
}
