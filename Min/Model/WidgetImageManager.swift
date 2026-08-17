//
//  Untitled.swift
//  Min
//
//  Created by dh on 2025/11/13.
//


import Foundation
import UIKit
import SwiftUI
import WidgetKit

class WidgetImageManager {
    static let shared = WidgetImageManager()
    private let appGroupSuiteName = "group.HaoDeng.Min.MinWidget"
    private let imageDirectoryName = "WidgetBackgrounds"
    
    private let memoryCache = NSCache<NSString, UIImage>()
    
    private init() {
        memoryCache.countLimit = 20
        memoryCache.totalCostLimit = 50 * 1024 * 1024
    }
    
    // 获取 App Group 容器 URL
    private var containerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupSuiteName)
    }
    
    // 获取图片目录 URL
    private var imageDirectoryURL: URL? {
        guard let containerURL = containerURL else { return nil }
        let directoryURL = containerURL.appendingPathComponent(imageDirectoryName)
        
        // 如果目录不存在，创建它
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        
        return directoryURL
    }
    
    // 保存图片到 App Group
    func saveImage(_ image: UIImage, withName name: String) -> Bool {
        guard let directoryURL = imageDirectoryURL else {
            print("WidgetImageManager: 无法获取图片目录")
            return false
        }
        
        let fileURL = directoryURL.appendingPathComponent(name)
        print("WidgetImageManager: 保存图片到: \(fileURL.path)")
        
        // 直接无损保存原图，避免任何重采样与有损压缩
        guard let imageData = image.pngData() else {
            print("WidgetImageManager: 无法将图片转换为 PNG 数据")
            return false
        }
        
        do {
            try imageData.write(to: fileURL)
            print("WidgetImageManager: 成功保存图片: \(name), 文件大小: \(imageData.count) bytes")
            
            // 验证文件是否真的保存了
            if FileManager.default.fileExists(atPath: fileURL.path) {
                print("WidgetImageManager: 验证成功，文件已存在")
            } else {
                print("WidgetImageManager: 警告：文件保存后验证失败")
            }
            
            return true
        } catch {
            print("WidgetImageManager: 保存图片失败: \(error)")
            return false
        }
    }
    
    // 从 App Group 加载图片（内存缓存优先）
    func loadImage(named name: String) -> UIImage? {
        let cacheKey = name as NSString
        
        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached
        }
        
        guard let directoryURL = imageDirectoryURL else { return nil }
        
        let fileURL = directoryURL.appendingPathComponent(name)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        
        guard let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else { return nil }
        
        memoryCache.setObject(image, forKey: cacheKey, cost: imageData.count)
        return image
    }
    
    // 删除图片
    func deleteImage(named name: String) -> Bool {
        memoryCache.removeAllObjects()
        
        guard let directoryURL = imageDirectoryURL else { return false }
        
        let fileURL = directoryURL.appendingPathComponent(name)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            print("删除图片失败: \(error)")
            return false
        }
    }
    
    // 生成唯一的图片文件名（PNG，无损）
    func generateImageName() -> String {
        return "background_\(UUID().uuidString).png"
    }
    
    // 保存裁剪后的图片（与 saveImage 相同：无损 PNG）
    func saveCroppedImage(_ image: UIImage, withName name: String) -> Bool {
        saveImage(image, withName: name)
    }

    func processWallpaper(
        _ image: UIImage,
        imageName: String
    ) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let imagePixelWidth = CGFloat(cgImage.width)
        let imagePixelHeight = CGFloat(cgImage.height)
        let screenPixelSize = CGSize(width: imagePixelWidth, height: imagePixelHeight)
        let machineIdentifier = WidgetFrameCalculator.currentMachineIdentifier()

        guard let frames = WidgetFrameCalculator.frameInfo(for: screenPixelSize, machineIdentifier: machineIdentifier) else {
            print("WidgetImageManager: 不支持的截图像素分辨率 \(Int(imagePixelWidth))x\(Int(imagePixelHeight)), machine=\(machineIdentifier)")
            return false
        }
        let topPixelRect = frames.topWidgetFrame
        let largePixelRect = frames.largeWidgetFrame

        print("WidgetImageManager: ===== Wallpaper Crop Debug =====")
        print("WidgetImageManager: machine=\(machineIdentifier), image(px)=\(imagePixelWidth)x\(imagePixelHeight)")
        print("WidgetImageManager: topFrame(px)=\(topPixelRect), largeFrame(px)=\(largePixelRect)")
        print("WidgetImageManager: y(top->large, px)=\(largePixelRect.minY - topPixelRect.minY)")

        let topCrop = cropImage(image, toRect: topPixelRect)
        let largeCrop = cropImage(image, toRect: largePixelRect)

        let topSaved = saveCroppedImage(topCrop, withName: "top_\(imageName)")
        let largeSaved = saveCroppedImage(largeCrop, withName: "large_\(imageName)")
        let success = topSaved && largeSaved

        if success {
            AppGroupStore.reloadWidgetsDebounced()
        }
        return success
    }

    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let imageRect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        let validRect = rect.intersection(imageRect)
        guard !validRect.isEmpty, let croppedCGImage = cgImage.cropping(to: validRect) else { return image }
        return UIImage(cgImage: croppedCGImage)
    }
}

