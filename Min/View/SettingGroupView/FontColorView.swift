//
//  FontColorView.swift
//  Min
//
//  Created by dh on 2025/1/20.
//

import SwiftUI
import UIKit

struct FontColorView: View {
    @Binding var fontSetting: FontSetting
    
    // 触觉反馈
    private let haptic = HapticFeedbackHelper.shared
    
    // 仅保留三种颜色：白色、黑色、自定义
    private let colorOptions: [FontColor] = [.white, .black, .custom]
    @State private var showCustomColorPicker = false
    
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
        .sheet(isPresented: $showCustomColorPicker) {
            SystemColorPicker(color: customColorBinding)
                .ignoresSafeArea()
                .minNativeSheet(detents: [.height(620)])
        }
        .onAppear {
            if !colorOptions.contains(fontSetting.fontColor) {
                fontSetting.fontColor = .white
            }
        }
    }
    
    @ViewBuilder
    private func colorOptionView(_ color: FontColor) -> some View {
        Button {
            fontSetting.fontColor = color
            haptic.selection()
            if color == .custom {
                showCustomColorPicker = true
            }
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
    
    private func selectionIndicator(for color: FontColor) -> AnyView {
        guard fontSetting.fontColor == color else {
            return AnyView(Circle().stroke(Color.clear, lineWidth: 0))
        }
        return AnyView(Circle().stroke(Color.white, lineWidth: 2))
    }
}

/// 系统取色面板。不用 SwiftUI ColorPicker 色井，避免多边形外观溢出。
private struct SystemColorPicker: UIViewControllerRepresentable {
    @Binding var color: Color

    func makeCoordinator() -> Coordinator {
        Coordinator(color: $color)
    }

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = true
        picker.selectedColor = UIColor(color)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIColorPickerViewController, context: Context) {
        context.coordinator.color = $color
    }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var color: Binding<Color>

        init(color: Binding<Color>) {
            self.color = color
        }

        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            color.wrappedValue = Color(uiColor: viewController.selectedColor)
        }

        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            color.wrappedValue = Color(uiColor: viewController.selectedColor)
        }
    }
}

#Preview {
    FontColorView(fontSetting: .constant(FontSetting()))
        .preferredColorScheme(.dark)
}
