//
//  FontColorView.swift
//  Min
//
//  Created by dh on 2025/1/20.
//

import SwiftUI

struct FontColorView: View {
    @Binding var fontSetting: FontSetting
    
    // 触觉反馈
    private let haptic = HapticFeedbackHelper.shared
    
    // 仅保留三种颜色：白色、黑色、自定义
    private let colorOptions: [FontColor] = [.white, .black, .custom]
    
    // 获取显示的颜色
    private func getDisplayColor(for color: FontColor) -> Color {
        if color == .custom {
            if let rgb = fontSetting.customColorRGB {
                return Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
            }
            return Color.gray.opacity(0.5)  // 如果还没有自定义颜色，显示灰色
        }
        return color.color
    }
    
    // 自定义颜色的绑定
    private var customColorBinding: Binding<Color> {
        Binding(
            get: {
                if let rgb = fontSetting.customColorRGB {
                    return Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha)
                }
                return Color.white
            },
            set: { newValue in
                let uiColor = UIColor(newValue)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                fontSetting.customColorRGB = (red: Double(red), green: Double(green), blue: Double(blue), alpha: Double(alpha))
                fontSetting.fontColor = .custom
            }
        )
    }
    
    // 色点直径与加减号图标一致，落在同一套三列宽度里
    private let circleSize: CGFloat = 22

    var body: some View {
        ZStack(alignment: .leading) {
            MinSettingChrome.rowBackground()
                .frame(height: MinSettingChrome.rowHeight)

            HStack(spacing: 0) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.leading, MinSettingChrome.rowControlInset)

                Text("字体颜色")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 10)

                Spacer(minLength: 8)

                MinSettingStepperCluster {
                    colorOptionView(.white)
                } center: {
                    colorOptionView(.black)
                } right: {
                    colorOptionView(.custom)
                }
            }
            .frame(height: MinSettingChrome.rowHeight)
        }
        .onAppear {
            if !colorOptions.contains(fontSetting.fontColor) {
                fontSetting.fontColor = .white
            }
        }
    }
    
    @ViewBuilder
    private func colorOptionView(_ color: FontColor) -> some View {
        if color == .custom {
            ZStack {
                ColorPicker("", selection: customColorBinding, supportsOpacity: true)
                    .labelsHidden()
                    .frame(width: circleSize, height: circleSize)
                    .opacity(0.015)
                customSwatch
                    .frame(width: circleSize, height: circleSize)
                    .allowsHitTesting(false)
                selectionIndicator(for: .custom)
                    .frame(width: circleSize, height: circleSize)
                    .allowsHitTesting(false)
            }
            .frame(width: circleSize, height: circleSize)
            .clipped()
            .contentShape(Circle())
            .onTapGesture {
                fontSetting.fontColor = .custom
                haptic.selection()
            }
        } else {
            Button {
                fontSetting.fontColor = color
                haptic.selection()
            } label: {
                Circle()
                    .fill(getDisplayColor(for: color))
                    .frame(width: circleSize, height: circleSize)
                    .overlay(
                        selectionIndicator(for: color)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: circleSize, height: circleSize)
            .contentShape(Circle())
        }
    }
    
    @ViewBuilder
    private var customSwatch: some View {
        if let rgb = fontSetting.customColorRGB {
            Circle()
                .fill(Color(red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: rgb.alpha))
        } else {
            // 未选择自定义颜色时，显示彩色画盘占位
            Circle()
                .fill(
                    AngularGradient(
                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                        center: .center
                    )
                )
                .overlay(
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.9))
                )
        }
    }
    
    private func selectionIndicator(for color: FontColor) -> AnyView {
        guard fontSetting.fontColor == color else {
            return AnyView(Circle().stroke(Color.clear, lineWidth: 0))
        }
        
        switch color {
        case .white:
            // 白色圆点在灰色背景上仅黑描边不够明显，使用黑内描+白外描增强对比
            return AnyView(
                ZStack {
                    Circle().stroke(Color.white.opacity(0.95), lineWidth: 3)
                    Circle().stroke(Color.black, lineWidth: 2)
                }
            )
        case .black:
            // 按需改回全白描边
            return AnyView(Circle().stroke(Color.white, lineWidth: 2))
        case .custom:
            return AnyView(Circle().stroke(getDisplayColor(for: .custom), lineWidth: 2))
        default:
            return AnyView(Circle().stroke(Color.white, lineWidth: 2))
        }
    }
}

#Preview {
    FontColorView(fontSetting: .constant(FontSetting()))
        .preferredColorScheme(.dark)
}
