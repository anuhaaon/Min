//
//  CustomFont.swift
//  Min
//
//  Created by dh on 2025/1/20.
//

import Foundation
import SwiftUI
import UIKit

/// iOS 内置字体名称枚举
enum iOSFontName: String, CaseIterable, Codable {
    case system = "System"
    case pingFangSC = "PingFangSC"
    case pingFangHK = "PingFangHK"
    case pingFangTC = "PingFangTC"
    case helvetica = "Helvetica"
    case helveticaNeue = "HelveticaNeue"
    case arial = "Arial"
    case timesNewRoman = "TimesNewRoman"
    case courier = "Courier"
    case courierNew = "CourierNew"
    case georgia = "Georgia"
    case verdana = "Verdana"
    case trebuchetMS = "TrebuchetMS"
    case arialHebrew = "ArialHebrew"
    case arialRoundedMTBold = "ArialRoundedMTBold"
    case chalkduster = "Chalkduster"
    case cochin = "Cochin"
    case copperplate = "Copperplate"
    case damascus = "Damascus"
    case devanagariSangamMN = "DevanagariSangamMN"
    case didot = "Didot"
    case futura = "Futura"
    case gillSans = "GillSans"
    case hiraginoSans = "HiraginoSans"
    case hiraginoMinchoProN = "HiraginoMinchoProN"
    case hoeflerText = "HoeflerText"
    case kailasa = "Kailasa"
    case kefa = "Kefa"
    case markerFelt = "MarkerFelt"
    case menlo = "Menlo"
    case noteworthy = "Noteworthy"
    case optima = "Optima"
    case palatino = "Palatino"
    case papyrus = "Papyrus"
    case partyLET = "PartyLET"
    case savoyeLET = "SavoyeLET"
    case snellRoundhand = "SnellRoundhand"
    case thonburi = "Thonburi"
    case zapfino = "Zapfino"
    
    var displayName: String {
        switch self {
        case .system: return "系统字体"
        case .pingFangSC: return "苹方-简"
        case .pingFangHK: return "苹方-港"
        case .pingFangTC: return "苹方-繁"
        case .helvetica: return "Helvetica"
        case .helveticaNeue: return "Helvetica Neue"
        case .arial: return "Arial"
        case .timesNewRoman: return "Times New Roman"
        case .courier: return "Courier"
        case .courierNew: return "Courier New"
        case .georgia: return "Georgia"
        case .verdana: return "Verdana"
        case .trebuchetMS: return "Trebuchet MS"
        case .arialHebrew: return "Arial Hebrew"
        case .arialRoundedMTBold: return "Arial Rounded MT Bold"
        case .chalkduster: return "Chalkduster"
        case .cochin: return "Cochin"
        case .copperplate: return "Copperplate"
        case .damascus: return "Damascus"
        case .devanagariSangamMN: return "Devanagari Sangam MN"
        case .didot: return "Didot"
        case .futura: return "Futura"
        case .gillSans: return "Gill Sans"
        case .hiraginoSans: return "Hiragino Sans"
        case .hiraginoMinchoProN: return "Hiragino Mincho ProN"
        case .hoeflerText: return "Hoefler Text"
        case .kailasa: return "Kailasa"
        case .kefa: return "Kefa"
        case .markerFelt: return "Marker Felt"
        case .menlo: return "Menlo"
        case .noteworthy: return "Noteworthy"
        case .optima: return "Optima"
        case .palatino: return "Palatino"
        case .papyrus: return "Papyrus"
        case .partyLET: return "Party LET"
        case .savoyeLET: return "Savoye LET"
        case .snellRoundhand: return "Snell Roundhand"
        case .thonburi: return "Thonburi"
        case .zapfino: return "Zapfino"
        }
    }
    
    /// 获取实际的字体名称字符串
    var fontName: String {
        switch self {
        case .system: return "System"
        case .pingFangSC: return "PingFangSC"
        case .pingFangHK: return "PingFangHK"
        case .pingFangTC: return "PingFangTC"
        case .helvetica: return "Helvetica"
        case .helveticaNeue: return "HelveticaNeue"
        case .arial: return "Arial"
        case .timesNewRoman: return "TimesNewRoman"
        case .courier: return "Courier"
        case .courierNew: return "CourierNew"
        case .georgia: return "Georgia"
        case .verdana: return "Verdana"
        case .trebuchetMS: return "TrebuchetMS"
        case .arialHebrew: return "ArialHebrew"
        case .arialRoundedMTBold: return "ArialRoundedMTBold"
        case .chalkduster: return "Chalkduster"
        case .cochin: return "Cochin"
        case .copperplate: return "Copperplate"
        case .damascus: return "Damascus"
        case .devanagariSangamMN: return "DevanagariSangamMN"
        case .didot: return "Didot"
        case .futura: return "Futura"
        case .gillSans: return "GillSans"
        case .hiraginoSans: return "HiraginoSans"
        case .hiraginoMinchoProN: return "HiraginoMinchoProN"
        case .hoeflerText: return "HoeflerText"
        case .kailasa: return "Kailasa"
        case .kefa: return "Kefa"
        case .markerFelt: return "MarkerFelt"
        case .menlo: return "Menlo"
        case .noteworthy: return "Noteworthy"
        case .optima: return "Optima"
        case .palatino: return "Palatino"
        case .papyrus: return "Papyrus"
        case .partyLET: return "PartyLET"
        case .savoyeLET: return "SavoyeLET"
        case .snellRoundhand: return "SnellRoundhand"
        case .thonburi: return "Thonburi"
        case .zapfino: return "Zapfino"
        }
    }
}

/// 字体样式枚举
enum FontStyle: String, CaseIterable, Codable {
    case regular = "regular"
    case medium = "medium"
    case semibold = "semibold"
    case bold = "bold"
    case heavy = "heavy"
    case black = "black"
    case light = "light"
    case thin = "thin"
    case ultraLight = "ultraLight"
    case italic = "italic"
    case boldItalic = "boldItalic"
    
    var displayName: String {
        switch self {
        case .regular: return "标准"
        case .medium: return "中等"
        case .semibold: return "半粗"
        case .bold: return "粗体"
        case .heavy: return "特粗"
        case .black: return "最粗"
        case .light: return "细体"
        case .thin: return "极细"
        case .ultraLight: return "超细"
        case .italic: return "斜体"
        case .boldItalic: return "粗斜体"
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        case .light: return .light
        case .thin: return .thin
        case .ultraLight: return .ultraLight
        case .italic: return .regular
        case .boldItalic: return .bold
        }
    }
    
    var isItalic: Bool {
        switch self {
        case .italic, .boldItalic: return true
        default: return false
        }
    }
}

/// 自定义字体项（经 ODR 下载后使用；PostScript 名 + 显示名）
struct BundledCustomFont: Identifiable {
    let id: String
    let postScriptName: String
    let displayName: String
    let odrTag: String
}

/// 将 ODR 目录映射为选择页使用的 BundledCustomFont 形态
enum BundledCustomFonts {
    static var all: [BundledCustomFont] {
        ODRFontCatalog.all.map {
            BundledCustomFont(
                id: $0.id,
                postScriptName: $0.postScriptName,
                displayName: $0.displayName,
                odrTag: $0.odrTag
            )
        }
    }

    static var families: [(name: String, fonts: [BundledCustomFont])] {
        ODRFontCatalog.families.map { (name: $0.name, fonts: $0.fonts.map {
            BundledCustomFont(
                id: $0.id,
                postScriptName: $0.postScriptName,
                displayName: $0.displayName,
                odrTag: $0.odrTag
            )
        }) }
    }
}

/// 自定义字体配置
struct CustomFont: Codable, Equatable {
    var fontName: iOSFontName
    var style: FontStyle
    /// 使用 Bundle 内 .ttf/.otf 时的 PostScript 名称；非 nil 时优先于 fontName
    var customFontPostScriptName: String?
    /// 自定义字体的显示名（用于设置页）
    var customFontDisplayName: String?
    /// App Group 内 ASCII 存储文件名（Widget 用这个找字体文件）
    var customFontStorageFileName: String?
    
    init(
        fontName: iOSFontName = .system,
        style: FontStyle = .regular,
        customFontPostScriptName: String? = nil,
        customFontDisplayName: String? = nil,
        customFontStorageFileName: String? = nil
    ) {
        self.fontName = fontName
        self.style = style
        self.customFontPostScriptName = customFontPostScriptName
        self.customFontDisplayName = customFontDisplayName
        self.customFontStorageFileName = customFontStorageFileName
    }
    
    /// 是否为自定义 TTF/OTF 字体
    var isCustomBundledFont: Bool {
        customFontPostScriptName != nil
    }
    
    /// 解析可用的 UIFont（会触发 App Group / Widget 本地注册）
    func resolvedUIFont(size: CGFloat) -> UIFont? {
        if let storage = customFontStorageFileName, !storage.isEmpty {
            if let resolved = AppGroupFontRegistrar.registerStorageFileName(storage),
               let uiFont = UIFont(name: resolved, size: size) {
                return uiFont
            }
        }
        if let name = customFontPostScriptName, !name.isEmpty {
            if let uiFont = UIFont(name: name, size: size) {
                return uiFont
            }
            if let item = ODRFontCatalog.all.first(where: { $0.postScriptName == name }),
               let resolved = AppGroupFontRegistrar.registerStorageFileName(item.storageFileName),
               let uiFont = UIFont(name: resolved, size: size) {
                return uiFont
            }
        }
        if fontName != .system,
           let uiFont = UIFont(name: fontName.fontName, size: size) {
            return uiFont
        }
        return nil
    }

    /// 生成 SwiftUI Font；动态注册字体用 UIFont 桥接，未注册则回退系统字体
    func createFont(size: CGFloat) -> Font {
        if let uiFont = resolvedUIFont(size: size) {
            return Font(uiFont)
        }
        if customFontPostScriptName != nil {
            return .system(size: size, weight: style.fontWeight, design: .default)
        }
        if fontName == .system {
            return .system(size: size, weight: style.fontWeight, design: .default)
        }
        return .system(size: size, weight: style.fontWeight, design: .default)
    }
    
    /// 显示名称
    var displayName: String {
        if let d = customFontDisplayName, !d.isEmpty {
            return "\(d) \(style.displayName)"
        }
        return "\(fontName.displayName) \(style.displayName)"
    }
    
    // MARK: - Codable（保持与旧版 FontSetting 兼容）
    enum CodingKeys: String, CodingKey {
        case fontName, style, customFontPostScriptName, customFontDisplayName, customFontStorageFileName
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        fontName = try c.decode(iOSFontName.self, forKey: .fontName)
        style = try c.decode(FontStyle.self, forKey: .style)
        customFontPostScriptName = try c.decodeIfPresent(String.self, forKey: .customFontPostScriptName)
        customFontDisplayName = try c.decodeIfPresent(String.self, forKey: .customFontDisplayName)
        customFontStorageFileName = try c.decodeIfPresent(String.self, forKey: .customFontStorageFileName)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(fontName, forKey: .fontName)
        try c.encode(style, forKey: .style)
        try c.encodeIfPresent(customFontPostScriptName, forKey: .customFontPostScriptName)
        try c.encodeIfPresent(customFontDisplayName, forKey: .customFontDisplayName)
        try c.encodeIfPresent(customFontStorageFileName, forKey: .customFontStorageFileName)
    }
}
