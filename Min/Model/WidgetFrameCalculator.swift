import Foundation
import UIKit

struct WidgetFrameInfo {
    let topWidgetFrame: CGRect
    let largeWidgetFrame: CGRect
}

class WidgetFrameCalculator {
    private struct DeviceCropProfile {
        /// 设备标识符（如 iPhone15,4）
        let identifiers: [String]
        /// 设备像素分辨率（px）
        let pixelResolution: CGSize
        /// TopWidget 裁剪区域（px）
        let topRect: CGRect
        /// LargeWidget 裁剪区域（px）
        let largeRect: CGRect
    }

    private static let profiles: [DeviceCropProfile] = [
        // 全部使用你提供的物理像素裁剪坐标（x, y, width, height）
        .init(
            identifiers: ["iPhone12,8", "iPhone14,6"],
            pixelResolution: CGSize(width: 750, height: 1334),
            topRect: CGRect(x: 36, y: 60, width: 678, height: 322),
            largeRect: CGRect(x: 36, y: 416, width: 678, height: 678)
        ), //（已適配）iPhone SE（第二/三代）
           // X 36~714 / Y TopWidegt:60~382 LargeWidegt:416~1094
        .init(
            identifiers: ["iPhone12,1"],
            pixelResolution: CGSize(width: 828, height: 1792),
            topRect: CGRect(x: 46, y: 140, width: 736, height: 346),
            largeRect: CGRect(x: 46, y: 528, width: 736, height: 734)
        ), // (已適配)iPhone 11
           // X 46~782 / Y TopWidegt: 140~486 LargeWidegt:528~1262
        .init(
            identifiers: ["iPhone12,3"],
            pixelResolution: CGSize(width: 1125, height: 2436),
            topRect: CGRect(x: 47, y: 183, width: 1031, height: 493),
            largeRect: CGRect(x: 47, y: 719, width: 1031, height: 1029)
        ), // (已適配)iPhone 11 Pro
           //  X 47~1078 / Y TopWidegt:183~676  LargeWidegt: 719~1748
        .init(
            identifiers: ["iPhone13,1", "iPhone14,4"],
            pixelResolution: CGSize(width: 1080, height: 2340),
            topRect: CGRect(x: 45, y: 193, width: 990, height: 474),
            largeRect: CGRect(x: 45, y: 708, width: 990, height: 989)
        ), // (已適配)iPhone 12 mini / 13 mini
           // X 45~1035 / Y TopWidegt:193~667  LargeWidegt: 708~1697
        .init(
            identifiers: ["iPhone13,2", "iPhone13,3", "iPhone14,5", "iPhone14,2", "iPhone14,7"],
            pixelResolution: CGSize(width: 1170, height: 2532),
            topRect: CGRect(x: 56, y: 201, width: 1058, height: 502),
            largeRect: CGRect(x: 56, y: 755, width: 1058, height: 1056)
        ), // 已適配）iPhone 12 / 12 Pro / 13 / 13 Pro / 14 / 16e / 17e
           // X 56~1114 / Y TopWidegt:201~703  LargeWidegt: 755~1811
        .init(
            identifiers: ["iPhone15,2", "iPhone15,4", "iPhone16,1"],
            pixelResolution: CGSize(width: 1179, height: 2556),
            topRect: CGRect(x: 58, y: 246, width: 1064, height: 504),
            largeRect: CGRect(x: 58, y: 804, width: 1064, height: 1062)
        ), // （已下载截图）iPhone 14 Pro / 15 / 15 Pro / 16
           // X 58~1122 / Y TopWidegt:246~750  LargeWidegt:804~1866
        .init(
            identifiers: ["iPhone18,1"],
            pixelResolution: CGSize(width: 1206, height: 2622),
            topRect: CGRect(x: 64, y: 270, width: 1079, height: 509),
            largeRect: CGRect(x: 64, y: 838, width: 1079, height: 1077)
        ), // （已适配）iPhone 17 / 16 Pro / 17 Pro
        .init(
            identifiers: ["iPhone12,5"],
            pixelResolution: CGSize(width: 1242, height: 2688),
            topRect: CGRect(x: 59, y: 198, width: 1124, height: 534),
            largeRect: CGRect(x: 59, y: 786, width: 1124, height:1122)
        ), //（已下载截图）iPhone 11 Pro Max
           // X 59~1183 / Y TopWidegt: 198~732 LargeWidegt: 786~1908
        .init(
            identifiers: [],
            pixelResolution: CGSize(width: 1260, height: 2736),
            topRect: CGRect(x: 65, y: 288, width: 1130, height: 534),
            largeRect: CGRect(x: 65, y: 882, width: 1130, height: 1128)
        ), // （已下载截图）iPhone Air
           // X 65~1195 / Y TopWidegt:288~822  LargeWidegt:882~2010
        .init(
            identifiers: ["iPhone13,4", "iPhone14,3", "iPhone14,8"],
            pixelResolution: CGSize(width: 1284, height: 2778),
            topRect: CGRect(x: 67, y: 216, width: 1151, height: 543),
            largeRect: CGRect(x: 67, y: 822, width: 1151, height: 1149)
        ), //（已下载截图）iPhone 12 Pro Max / 13 Pro Max / 14 Plus
           // X 67~1218 / Y TopWidegt:216~759  LargeWidegt:822~1971
        .init(
            identifiers: ["iPhone15,3", "iPhone15,5", "iPhone16,2"],
            pixelResolution: CGSize(width: 1290, height: 2796),
            topRect: CGRect(x: 69, y: 252, width: 1152, height: 544),
            largeRect: CGRect(x: 69, y: 857, width: 1152, height: 1152)
        ), //（已下载截图）iPhone 14 Pro Max / 15 Plus / 16 Plus / 15 Pro Max
           // X 69~1221 / Y TopWidegt:252~796  LargeWidegt:857~2009
        .init(
            identifiers: [],
            pixelResolution: CGSize(width: 1320, height: 2868),
            topRect: CGRect(x: 75, y: 282, width: 1170, height: 550),
            largeRect: CGRect(x: 75, y: 899, width: 1170, height: 1170)
        ) // （已下载截图）iPhone 16 Pro Max / 17 Pro Max
          // X 75~1245 / Y TopWidegt: 282~832 LargeWidegt:899~2069
        
    ]

    static func currentMachineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    /// 机型标识符优先，分辨率次之；不做任何几何矫正。
    static func frameInfo(for screenPixelSize: CGSize, machineIdentifier: String) -> WidgetFrameInfo? {
        if let matchedByMachine = profiles.first(where: { $0.identifiers.contains(machineIdentifier) }) {
            return WidgetFrameInfo(
                topWidgetFrame: matchedByMachine.topRect,
                largeWidgetFrame: matchedByMachine.largeRect
            )
        }

        guard let matchedByResolution = profiles.first(where: {
            Int($0.pixelResolution.width) == Int(screenPixelSize.width) &&
            Int($0.pixelResolution.height) == Int(screenPixelSize.height)
        }) else { return nil }

        return WidgetFrameInfo(
            topWidgetFrame: matchedByResolution.topRect,
            largeWidgetFrame: matchedByResolution.largeRect
        )
    }

    static func frameInfo(for screenPixelSize: CGSize) -> WidgetFrameInfo? {
        frameInfo(for: screenPixelSize, machineIdentifier: currentMachineIdentifier())
    }

    static func isSupportedResolution(_ screenPixelSize: CGSize) -> Bool {
        let machineIdentifier = currentMachineIdentifier()
        if profiles.contains(where: { $0.identifiers.contains(machineIdentifier) }) {
            return true
        }
        return profiles.contains(where: {
            Int($0.pixelResolution.width) == Int(screenPixelSize.width) &&
            Int($0.pixelResolution.height) == Int(screenPixelSize.height)
        })
    }
}
