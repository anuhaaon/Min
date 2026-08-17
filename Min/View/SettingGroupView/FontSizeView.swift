//
//  FontSizeView.swift
//  Min
//
//  Created by dh on 2025/1/20.
//

import SwiftUI

struct FontSizeView: View {
    @Binding var fontSetting: FontSetting
    
    // 触觉反馈
    private let haptic = HapticFeedbackHelper.shared
    
    var body: some View {
        // 字体大小选择器
        ZStack(alignment: .leading) {
            MinSettingChrome.rowBackground()
                .frame(height: MinSettingChrome.rowHeight)
            
            HStack(spacing: 0) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.leading, MinSettingChrome.rowControlInset)
                
                Text("字体大小")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 10)
                
                Spacer(minLength: 8)

                MinSettingStepperCluster {
                    Button {
                        if fontSetting.customFontSize > 20 {
                            fontSetting.customFontSize -= 1
                            haptic.light()
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(fontSetting.customFontSize > 20 ? .white : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(fontSetting.customFontSize <= 20)
                } center: {
                    Text("\(Int(fontSetting.customFontSize))")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                } right: {
                    Button {
                        if fontSetting.customFontSize < 50 {
                            fontSetting.customFontSize += 1
                            haptic.light()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(fontSetting.customFontSize < 50 ? .white : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(fontSetting.customFontSize >= 50)
                }
            }
            .frame(height: MinSettingChrome.rowHeight)
        }
    }
}

#Preview {
    FontSizeView(fontSetting: .constant(FontSetting()))
        .preferredColorScheme(.dark)
}
