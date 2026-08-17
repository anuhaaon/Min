//
//  MinSettingChrome.swift
//  Min
//
//  个性化页统一尺寸：圆角、行高、间距；Sheet 上下留白统一
//

import SwiftUI

enum MinSettingChrome {
    /// 选项行 / 预览共用圆角
    static let corner: CGFloat = 20
    /// 行内小按钮（Aa、选择背景等）
    static let chipCorner: CGFloat = 8
    /// 选项行高度
    static let rowHeight: CGFloat = 60
    /// Setting 内容左右边距（预览与选项同宽）
    static let contentInset: CGFloat = 20
    /// 分组之间
    static let sectionSpacing: CGFloat = 18
    /// 同组选项行间距
    static let rowSpacing: CGFloat = 10
    /// Sheet：顶→标题、标题→内容、内容→底 统一间距
    static let sheetChromeGap: CGFloat = 28
    /// 行描边
    static let stroke = Color.white.opacity(0.08)
    /// 行底色
    static let rowFill = Color.gray.opacity(0.18)
    /// 行内左右边距（标题与右侧控件共用）
    static let rowControlInset: CGFloat = 28
    /// 字体大小 / 间距 / 颜色 右侧三列：减号·色点 / 数值·中间色 / 加号·自定义
    static let stepperSideWidth: CGFloat = 24
    static let stepperCenterWidth: CGFloat = 40
    static let stepperSpacing: CGFloat = 16
    /// 长列表类 sheet（字体选择）仍用大高度
    static let sheetDetents: Set<PresentationDetent> = [.large]

    static func rowBackground() -> some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .foregroundStyle(rowFill)
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(stroke, lineWidth: 0.5)
            )
    }
}

extension View {
    /// Setting 内长列表 sheet（字体等）
    func minSettingSheet() -> some View {
        minNativeSheet(detents: MinSettingChrome.sheetDetents)
    }
}

/// 设置行右侧三列，保证字体大小 / 间距 / 颜色的按钮 X 轴对齐
struct MinSettingStepperCluster<Left: View, Center: View, Right: View>: View {
    @ViewBuilder var left: () -> Left
    @ViewBuilder var center: () -> Center
    @ViewBuilder var right: () -> Right

    var body: some View {
        HStack(spacing: MinSettingChrome.stepperSpacing) {
            left()
                .frame(width: MinSettingChrome.stepperSideWidth, alignment: .center)
            center()
                .frame(width: MinSettingChrome.stepperCenterWidth, alignment: .center)
            right()
                .frame(width: MinSettingChrome.stepperSideWidth, alignment: .center)
        }
        .padding(.trailing, MinSettingChrome.rowControlInset)
    }
}
