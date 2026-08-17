//
//  MinNativeSheet.swift
//  Min
//
//  Setting 等处统一使用系统原生 sheet 外观（iOS 26：设备圆角 + Liquid Glass）
//  不要自定义 presentationCornerRadius / 描边 / presentationBackground，避免盖住系统样式
//

import SwiftUI

extension View {
    /// 跟随系统 sheet：圆角与 iPhone 一致，半屏内缩与 Liquid Glass 由系统控制
    func minNativeSheet(
        detents: Set<PresentationDetent> = [.medium, .large],
        dragIndicator: Visibility = .visible
    ) -> some View {
        self
            .preferredColorScheme(.dark)
            .presentationDetents(detents)
            .presentationDragIndicator(dragIndicator)
    }
}
