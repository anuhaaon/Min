//
//  Untitled.swift
//  Min
//
//  Created by KangXiang on 2025/6/17.
//
//

import Foundation
import SwiftUI

/// 用于主应用和 Widget 之间共享的对齐偏好
enum TextAlignmentType: String, CaseIterable, Codable {
    case leading
    case center
    case trailing

    /// 转成 SwiftUI 的 Alignment
    var asAlignment: Alignment {
        switch self {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    /// 转成 SwiftUI 的 TextAlignment（如果你在普通 Text 里用 .multilineTextAlignment）
    var asTextAlignment: TextAlignment {
        switch self {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    /// 图标名称（可选，用于按钮展示）
    var iconName: String {
        switch self {
        case .leading:  return "align.horizontal.left"
        case .center:   return "align.horizontal.center"
        case .trailing: return "align.horizontal.right"
        }
    }
}

