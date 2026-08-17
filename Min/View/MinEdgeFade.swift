//
//  MinEdgeFade.swift
//  Min
//
//  列表边缘渐隐：用 Material + 渐变遮罩替代私有 CAFilter VariableBlur。
//

import SwiftUI

struct MinEdgeFade: View {
    enum Edge {
        case top
        case bottom
    }

    var edge: Edge
    var height: CGFloat = 30

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    LinearGradient(
                        colors: maskColors,
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            LinearGradient(
                colors: overlayColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
        }
        .frame(height: height)
        .allowsHitTesting(false)
    }

    private var maskColors: [Color] {
        switch edge {
        case .top:
            return [.black, .black.opacity(0.4), .clear]
        case .bottom:
            return [.clear, .black.opacity(0.4), .black]
        }
    }

    private var overlayColors: [Color] {
        switch edge {
        case .top:
            return [.black, .clear]
        case .bottom:
            return [.clear, .black]
        }
    }
}
