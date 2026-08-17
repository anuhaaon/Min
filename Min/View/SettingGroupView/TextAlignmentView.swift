//
//  TextAlignmentView.swift
//  Min
//
//  Created by dh on 2025/6/12.
//


import SwiftUI

struct TextAlignmentView: View {
    // 触觉反馈
    private let haptic = HapticFeedbackHelper.shared
    
    @Binding var selectedAlignment: TextAlignment
    
    enum TextAlignment: CaseIterable {
        case leading, center, trailing
        
        var icon: String {
            switch self {
            case .leading: return "align.horizontal.left"
            case .center: return "align.horizontal.center"
            case .trailing: return "align.horizontal.right"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            MinSettingChrome.rowBackground()
                .frame(height: MinSettingChrome.rowHeight)
            
            HStack(spacing: 0) {
                Image(systemName: "trapezoid.and.line.vertical")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.leading, 28)
                
                Text("对齐方式")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.leading, 10)
                
                Spacer()
                
                HStack(spacing: 10) {
                        Button {
                            selectedAlignment = .leading
                            haptic.selection()
                        } label: {
                            RoundedRectangle(cornerRadius: MinSettingChrome.chipCorner, style: .continuous)
                                .foregroundStyle(selectedAlignment == .leading ? Color.white : Color.gray.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: TextAlignment.leading.icon)
                                        .font(.system(size: 13))
                                        .foregroundStyle(selectedAlignment == .leading ? .black : .white)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            selectedAlignment = .center
                            haptic.selection()
                        } label: {
                            RoundedRectangle(cornerRadius: MinSettingChrome.chipCorner, style: .continuous)
                                .foregroundStyle(selectedAlignment == .center ? Color.white : Color.gray.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: TextAlignment.center.icon)
                                        .font(.system(size: 13))
                                        .foregroundStyle(selectedAlignment == .center ? .black : .white)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            selectedAlignment = .trailing
                            haptic.selection()
                        } label: {
                            RoundedRectangle(cornerRadius: MinSettingChrome.chipCorner, style: .continuous)
                                .foregroundStyle(selectedAlignment == .trailing ? Color.white : Color.gray.opacity(0.2))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: TextAlignment.trailing.icon)
                                        .font(.system(size: 13))
                                        .foregroundStyle(selectedAlignment == .trailing ? .black : .white)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                }
                .padding(.trailing, 28)
            }
            .frame(height: MinSettingChrome.rowHeight)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    TextAlignmentView(selectedAlignment: .constant(.leading))
}
