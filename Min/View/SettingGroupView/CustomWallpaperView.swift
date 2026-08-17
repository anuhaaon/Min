//
//  test.swift
//  Min
//
//  Created by dh on 2025/11/12.
//


import SwiftUI

struct CustomWallpaperView: View {
    @Binding var fontSetting: FontSetting
    @State private var showGuideSheet = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            MinSettingChrome.rowBackground()
                .frame(height: MinSettingChrome.rowHeight)
            
            HStack(spacing: 0) {
                Image(systemName: "photo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.leading, 28)
                
                Text("背景")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 10)
                
                Spacer(minLength: 12)
                
                // 打开壁纸引导页
                Button {
                    showGuideSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 9))
                        Text("选择背景")
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
        .sheet(isPresented: $showGuideSheet) {
            WallpaperGuideView(fontSetting: $fontSetting)
                .minNativeSheet(detents: [.height(WallpaperGuideView.preferredSheetHeight)])
        }
    }
}

#Preview {
    CustomWallpaperView(fontSetting: .constant(FontSetting()))
        .preferredColorScheme(.dark)
}

