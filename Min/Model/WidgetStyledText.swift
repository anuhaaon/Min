//
//  WidgetStyledText.swift
//  Min
//
//  桌面 Widget 自定义字体：用位图绘制，避免 chronod 无法加载动态字体文件
//

import SwiftUI
import UIKit
import WidgetKit

// MARK: - 渲染缓存
private final class RenderCache: @unchecked Sendable {
    static let shared = RenderCache()
    private var cache: [String: UIImage] = [:]
    private let lock = NSLock()

    func image(forKey key: String) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        return cache[key]
    }
    func store(_ image: UIImage, forKey key: String) {
        lock.lock(); defer { lock.unlock() }
        if cache.count > 200 { cache.removeAll() }
        cache[key] = image
    }
}

/// Widget 内显示文字。自定义 ODR 字体走 UIImage；系统字体仍用 Text。
///
/// - Parameter asyncRender: Widget extension 必须传 `false`（快照渲染不支持异步状态更新）。
///   主 App 传 `true`（默认）以避免主线程阻塞。
struct WidgetStyledText: View {
    let text: String
    let customFont: CustomFont
    let size: CGFloat
    let color: Color
    var maxWidth: CGFloat? = nil
    var tracking: CGFloat = 1.6
    /// Widget extension 传 false，主 App 传 true（默认）
    var asyncRender: Bool = true

    @State private var renderedImage: UIImage? = nil

    private var cacheKey: String {
        "\(text)|\(customFont.customFontStorageFileName ?? "")|\(customFont.customFontPostScriptName ?? "sys")|\(size)|\(UIColor(color).description)|\(maxWidth ?? -1)|\(tracking)"
    }

    var body: some View {
        if customFont.isCustomBundledFont,
           let uiFont = customFont.resolvedUIFont(size: size) {
            if asyncRender {
                asyncImageView(font: uiFont)
            } else {
                syncImageView(font: uiFont)
            }
        } else {
            Text(text)
                .font(customFont.createFont(size: size))
                .tracking(tracking)
                .foregroundColor(color)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    // MARK: 同步路径（Widget 快照使用）
    private func syncImageView(font: UIFont) -> some View {
        let key = cacheKey
        let img = RenderCache.shared.image(forKey: key)
            ?? Self.renderImage(
                text: text,
                font: font,
                color: UIColor(color),
                maxWidth: maxWidth,
                kern: tracking,
                scale: UIScreen.main.scale
            )
        if let img {
            RenderCache.shared.store(img, forKey: key)
            return AnyView(
                renderedImageView(img)
            )
        } else {
            return AnyView(Color.clear.frame(maxHeight: size * 1.35))
        }
    }

    // MARK: 异步路径（主 App 使用，不阻塞主线程）
    private func asyncImageView(font: UIFont) -> some View {
        Group {
            if let img = renderedImage {
                renderedImageView(img)
            } else {
                Color.clear
                    .frame(maxHeight: size * 1.35)
            }
        }
        .task(id: cacheKey) {
            await renderAsync(font: font)
        }
    }

    @MainActor
    private func renderAsync(font: UIFont) async {
        let key = cacheKey
        if let cached = RenderCache.shared.image(forKey: key) {
            renderedImage = cached
            return
        }
        // 动态注册字体必须在主线程绘制，后台线程会落到缺字（方框问号）
        let img = Self.renderImage(
            text: text,
            font: font,
            color: UIColor(color),
            maxWidth: maxWidth,
            kern: tracking,
            scale: UIScreen.main.scale
        )
        guard let img, key == cacheKey else { return }
        RenderCache.shared.store(img, forKey: key)
        renderedImage = img
    }

    @ViewBuilder
    private func renderedImageView(_ img: UIImage) -> some View {
        Image(uiImage: img)
            .interpolation(.high)
            .frame(
                width: maxWidth ?? img.size.width,
                height: size * 1.35,
                alignment: .leading
            )
            .clipped()
            .accessibilityLabel(text)
    }

    // MARK: Core Graphics 渲染（可在任意线程调用）
    nonisolated static func renderImage(
        text: String,
        font: UIFont,
        color: UIColor,
        maxWidth: CGFloat?,
        kern: CGFloat = 1.6,
        scale: CGFloat
    ) -> UIImage? {
        guard !text.isEmpty else { return nil }

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        paragraph.alignment = .left

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .kern: kern
        ]
        let attributed = NSAttributedString(string: text, attributes: attributes)
        var drawSize = attributed.size()
        drawSize.width = ceil(drawSize.width)
        drawSize.height = ceil(max(drawSize.height, font.lineHeight))

        if let maxWidth, maxWidth > 0, drawSize.width > maxWidth {
            drawSize.width = floor(maxWidth)
        }

        guard drawSize.width > 0, drawSize.height > 0 else { return nil }

        UIGraphicsBeginImageContextWithOptions(drawSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        let bounds = CGRect(origin: .zero, size: drawSize)
        attributed.draw(with: bounds, options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine], context: nil)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
