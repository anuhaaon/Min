//
//  WallpaperGuideView.swift
//  Min
//
//  壁纸设置引导页：教程视频 + 上传截图
//

import SwiftUI
import PhotosUI
import AVKit
import WidgetKit
import UIKit

struct WallpaperGuideView: View {
    @Binding var fontSetting: FontSetting

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var previewImage: UIImage?
    @State private var showSizeErrorAlert = false
    @State private var sizeErrorMessage = ""

    private let haptic = HapticFeedbackHelper.shared
    private static let gap = MinSettingChrome.sheetChromeGap
    private static let titleBlockHeight: CGFloat = 34 + 6 + 40 // 标题 + 间距 + 两行说明
    private static let buttonHeight: CGFloat = 54
    /// 预览正方形边长（略收，避免 sheet 过高）
    private static let previewSide: CGFloat = 280

    /// 顶→标题、标题区→预览、预览→按钮、按钮→底 四处等距
    static var preferredSheetHeight: CGFloat {
        gap
        + titleBlockHeight
        + gap
        + previewSide
        + gap
        + buttonHeight
        + gap
    }

    private var currentScreen: UIScreen? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.screen
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("壁纸")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                Text("长按主屏幕最后一页")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                Text("保持不动，左滑截取空白屏幕截图")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, Self.gap)
            .padding(.bottom, Self.gap)
            .padding(.horizontal, MinSettingChrome.contentInset)

            centerContent(side: Self.previewSide)
                .frame(width: Self.previewSide, height: Self.previewSide)
                .frame(maxWidth: .infinity)

            uploadButton
                .padding(.horizontal, MinSettingChrome.contentInset)
                .padding(.top, Self.gap)
                .padding(.bottom, Self.gap)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
        .alert("图片尺寸不符合要求", isPresented: $showSizeErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(sizeErrorMessage)
        }
        .onAppear {
            refreshPreviewImage()
        }
    }

    // MARK: - Center Content

    @ViewBuilder
    private func centerContent(side: CGFloat) -> some View {
        if let previewImage {
            wallpaperPreview(image: previewImage, side: side)
        } else {
            tutorialSection(side: side)
        }
    }

    /// 壁纸预览：完整显示截图；外框为不超出可用区域的圆角正方形
    private func wallpaperPreview(image: UIImage, side: CGFloat) -> some View {
        let inset: CGFloat = 3
        let corner: CGFloat = MinSettingChrome.corner

        return ZStack(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.black)

                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: side - inset * 2, maxHeight: side - inset * 2)
                    .clipShape(RoundedRectangle(cornerRadius: corner - 2, style: .continuous))

                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
            }
            .frame(width: side, height: side)

            Button {
                deleteBackground()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            }
            .offset(x: 8, y: -8)
        }
        .frame(width: side, height: side)
    }

    /// 截图教程：圆角正方形，完整显示演示内容
    private func tutorialSection(side: CGFloat) -> some View {
        let inset: CGFloat = 3
        let corner: CGFloat = MinSettingChrome.corner

        return ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(Color.black)

            LoopingVideoPlayer(videoName: "screenshot_tutorial", videoGravity: .resizeAspect)
                .frame(width: side - inset * 2, height: side - inset * 2)
                .clipShape(RoundedRectangle(cornerRadius: corner - 2, style: .continuous))

            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
        }
        .frame(width: side, height: side)
    }

    // MARK: - Upload Button

    private var uploadButton: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 15, weight: .medium))
                Text("导入截图")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Self.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: MinSettingChrome.corner, style: .continuous)
                    .fill(Color.white.opacity(0.15))
            )
        }
        .onChange(of: selectedItem) { oldValue, newItem in
            Task {
                if let newItem = newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let rawImage = UIImage(data: data),
                       let cgImage = rawImage.cgImage {
                        let screenScale = await MainActor.run { self.currentScreen?.nativeScale ?? 3.0 }
                        let correctedImage = UIImage(
                            cgImage: cgImage,
                            scale: screenScale,
                            orientation: rawImage.imageOrientation
                        )
                        await MainActor.run {
                            selectedImage = correctedImage
                            if validateImageSize(correctedImage) {
                                saveImage(correctedImage)
                            } else {
                                showSizeErrorAlert = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Image Validation & Save (复用 CustomWallpaperView 的逻辑)
    
    private func validateImageSize(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else {
            sizeErrorMessage = "图片读取失败，请重新选择截图。"
            return false
        }

        let imagePixelSize = CGSize(width: cgImage.width, height: cgImage.height)
        guard let nativeBounds = currentScreen?.nativeBounds else {
            sizeErrorMessage = "无法获取屏幕信息，请重试。"
            return false
        }
        let portraitSize = CGSize(
            width: min(nativeBounds.width, nativeBounds.height),
            height: max(nativeBounds.width, nativeBounds.height)
        )

        let imageWidth = Int(imagePixelSize.width.rounded())
        let imageHeight = Int(imagePixelSize.height.rounded())
        let portraitWidth = Int(portraitSize.width.rounded())
        let portraitHeight = Int(portraitSize.height.rounded())

        guard imageWidth == portraitWidth, imageHeight == portraitHeight else {
            sizeErrorMessage = "仅支持当前设备的原始竖版全屏截图。\n当前设备：\(portraitWidth) × \(portraitHeight)\n上传图片：\(imageWidth) × \(imageHeight)"
            return false
        }

        guard WidgetFrameCalculator.isSupportedResolution(portraitSize) else {
            sizeErrorMessage = "当前设备分辨率 \(portraitWidth) × \(portraitHeight) 尚未配置裁剪坐标。"
            return false
        }

        return true
    }
    
    private func saveImage(_ image: UIImage) {
        let imageName = WidgetImageManager.shared.generateImageName()
        
        if WidgetImageManager.shared.saveImage(image, withName: imageName) {
            // 删除旧图片
            if let oldImageName = fontSetting.backgroundImageName {
                _ = WidgetImageManager.shared.deleteImage(named: oldImageName)
                _ = WidgetImageManager.shared.deleteImage(named: "top_\(oldImageName)")
                _ = WidgetImageManager.shared.deleteImage(named: "large_\(oldImageName)")
            }

            _ = WidgetImageManager.shared.processWallpaper(image, imageName: imageName)
            fontSetting.backgroundImageName = imageName
            saveFontSettingToSharedContainer()
            
            refreshPreviewImage()
        }
    }
    
    private func deleteBackground() {
        haptic.medium()
        if let imageName = fontSetting.backgroundImageName {
            _ = WidgetImageManager.shared.deleteImage(named: imageName)
            _ = WidgetImageManager.shared.deleteImage(named: "top_\(imageName)")
            _ = WidgetImageManager.shared.deleteImage(named: "large_\(imageName)")
            fontSetting.backgroundImageName = nil
            previewImage = nil
            saveFontSettingToSharedContainer()
        }
    }
    
    private func refreshPreviewImage() {
        guard let imageName = fontSetting.backgroundImageName else {
            previewImage = nil
            return
        }
        Task(priority: .userInitiated) {
            let loaded = WidgetImageManager.shared.loadImage(named: imageName)
            await MainActor.run {
                previewImage = loaded
            }
        }
    }
    
    private func saveFontSettingToSharedContainer() {
        let encoder = JSONEncoder()
        do {
            let fontSettingData = try encoder.encode(fontSetting)
            AppGroupStore.set(fontSettingData, forKey: "fontSetting")
            AppGroupStore.reloadWidgetsDebounced()
        } catch {
            print("WallpaperGuideView: 保存字体设置失败: \(error)")
        }
    }
}

#Preview {
    WallpaperGuideView(fontSetting: .constant(FontSetting()))
        .preferredColorScheme(.dark)
}

// MARK: - 循环视频播放器

/// 使用 AVPlayerLooper 实现无缝循环播放的 UIViewRepresentable
struct LoopingVideoPlayer: UIViewRepresentable {
    let videoName: String
    var videoGravity: AVLayerVideoGravity = .resizeAspect

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.configure(with: videoName, videoGravity: videoGravity)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: ()) {
        uiView.cleanup()
    }
}

/// 承载 AVPlayerLayer + AVPlayerLooper 的 UIView
class PlayerContainerView: UIView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    func configure(with videoName: String, videoGravity: AVLayerVideoGravity = .resizeAspect) {
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            print("LoopingVideoPlayer: 找不到视频文件: \(videoName).mp4")
            return
        }

        let item = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none

        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        player = queuePlayer

        let layer = self.layer as! AVPlayerLayer
        layer.player = queuePlayer
        layer.videoGravity = videoGravity
        playerLayer = layer

        queuePlayer.play()
    }

    func cleanup() {
        player?.pause()
        looper = nil
        player = nil
        playerLayer?.player = nil
    }
}
