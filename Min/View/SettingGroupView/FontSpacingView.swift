//
//  FontSpacingView.swift
//  Min
//
//  Created by dh on 2026/3/7.
//

import SwiftUI

struct FontSpacingView: View {
    @Binding var fontSetting: FontSetting
    private let haptic = HapticFeedbackHelper.shared

    var body: some View {
        ZStack(alignment: .leading) {
            MinSettingChrome.rowBackground()
                .frame(height: MinSettingChrome.rowHeight)

            HStack(spacing: 0) {
                Image(systemName: "space")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.leading, MinSettingChrome.rowControlInset)

                Text("文字间距")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 10)

                Spacer(minLength: 8)

                MinSettingStepperCluster {
                    Button {
                        if fontSetting.fontSpacing > 0 {
                            fontSetting.fontSpacing -= 1
                            haptic.light()
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(fontSetting.fontSpacing > 0 ? .white : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(fontSetting.fontSpacing <= 0)
                } center: {
                    Text("\(Int(fontSetting.fontSpacing))")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                } right: {
                    Button {
                        if fontSetting.fontSpacing < 20 {
                            fontSetting.fontSpacing += 1
                            haptic.light()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(fontSetting.fontSpacing < 20 ? .white : .gray)
                    }
                    .buttonStyle(.plain)
                    .disabled(fontSetting.fontSpacing >= 20)
                }
            }
            .frame(height: MinSettingChrome.rowHeight)
        }
    }
}

#Preview {
    FontSpacingView(fontSetting: .constant(FontSetting()))
        .preferredColorScheme(.dark)
}
