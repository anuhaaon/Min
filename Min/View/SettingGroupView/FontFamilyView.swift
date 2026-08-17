//
//  FontFamilyView.swift
//  Min
//
//  Created by dh on 2025/1/20.
//

import SwiftUI

struct FontFamilyView: View {
    @Binding var customFont: CustomFont
    @State private var isShowingFontPicker = false
    
    private let haptic = HapticFeedbackHelper.shared
    
    var body: some View {
        ZStack(alignment: .leading) {
            MinSettingChrome.rowBackground()
                .frame(height: MinSettingChrome.rowHeight)
            
            HStack(spacing: 0) {
                Image(systemName: "textformat")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.leading, 28)
                
                Text("字体设置")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 10)
                
                Spacer(minLength: 8)
                
                Button {
                    haptic.light()
                    isShowingFontPicker = true
                } label: {
                    HStack(spacing: 6) {
                        WidgetStyledText(
                            text: "Aa",
                            customFont: customFont,
                            size: 13,
                            color: .white
                        )
                        .fixedSize()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: MinSettingChrome.chipCorner, style: .continuous).fill(Color.gray.opacity(0.3)))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 28)
            }
            .frame(height: MinSettingChrome.rowHeight)
        }
        .sheet(isPresented: $isShowingFontPicker) {
            FontsPickerView(customFont: $customFont)
                .minSettingSheet()
        }
    }
}

#Preview {
    FontFamilyView(customFont: .constant(CustomFont()))
        .environmentObject(SubscriptionManager.shared)
        .preferredColorScheme(.dark)
}


