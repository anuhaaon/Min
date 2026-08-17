//
//  ODRFontCatalog.swift
//  Min
//
//  自定义字体目录：默认不内嵌，全部通过 ODR Tag 按需下载。
//

import Foundation

struct ODRFontItem: Identifiable, Hashable {
    let id: String
    let fileName: String
    let postScriptName: String
    let displayName: String
    let familyName: String
    let odrTag: String

    /// App Group 内使用的纯 ASCII 文件名（避免中文路径导致 Widget 读不到/注册失败）
    var storageFileName: String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        var hash: UInt64 = 5381
        for byte in id.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(format: "f%016llx.\(ext.isEmpty ? "ttf" : ext)", hash)
    }
}

enum ODRFontCatalog {
    /// 免费可用字体家族（系统字体另列；顺序即选择页顺序）
    static let freeFamilyNames: [String] = [
        "仓耳非白",
        "抖音美好体",
    ]

    /// Pro 字体家族展示顺序（按桌面小组件可读性 / 风格分组）
    static let proFamilyOrder: [String] = [
        // 无衬线 / 标题向
        "乡立方黑体",
        "Aa厚底黑",
        "余繁新语",
        "铁蒺藜",
        "快看世界体",
        "鼎猎西大体",
        // 手写 / 活泼
        "白路俏丽手写体",
        "荷塘月色手写体",
        "呆萌手写体",
        "小可奶酪体",
        "阿朱泡泡体",
        "千图小兔体",
        "也字工厂小石头",
        "字制区喜脉喜欢体",
        "文心喜乐体",
        "新叶念体",
        "今年也要加油鸭",
        "鸿雷小纸条青春体",
        // 书法 / 古风
        "草书",
        "南构无恙行书",
        "墨趣古风体",
        "南西初夏宋",
        "她屿山海",
        "云峰寒蝉体",
        "明达明达无锋体",
        "簡語生活體",
        "重庆山城棒棒体",
        "栗壳坚坚体",
        "猫啃珠圆体",
        // 像素 / 点阵
        "中文像素字体",
        "精品点阵体",
        "Fusion Pixel 10px",
        // 拉丁 / 装饰
        "Caveat",
        "Poor Handwriting",
        "Ouvrieres",
        "Rubik",
        "Victor Mono",
    ]

    static func isFreeFamily(_ name: String) -> Bool {
        freeFamilyNames.contains(name)
    }

    static let all: [ODRFontItem] = [
        ODRFontItem(id: "Aa厚底黑", fileName: "Aa厚底黑.ttf", postScriptName: "AaHouDiHei", displayName: "Aa厚底黑", familyName: "Aa厚底黑", odrTag: "Fonts.AaHouDiHei"),
        ODRFontItem(id: "Caveat-Bold", fileName: "Caveat-Bold.ttf", postScriptName: "Caveat-Bold", displayName: "Caveat 粗体", familyName: "Caveat", odrTag: "Fonts.Caveat"),
        ODRFontItem(id: "Caveat-Regular", fileName: "Caveat-Regular.ttf", postScriptName: "Caveat-Regular", displayName: "Caveat 常规", familyName: "Caveat", odrTag: "Fonts.Caveat"),
        ODRFontItem(id: "Ouvrieres-affamees", fileName: "Ouvrieres-affamees.ttf", postScriptName: "Ouvrieres-affamees", displayName: "Ouvrieres Affamées", familyName: "Ouvrieres", odrTag: "Fonts.Ouvrieres"),
        ODRFontItem(id: "Ouvrieres-rassasiees", fileName: "Ouvrieres-rassasiees.ttf", postScriptName: "Ouvrieres-rassasiees", displayName: "Ouvrieres Rassasiées", familyName: "Ouvrieres", odrTag: "Fonts.Ouvrieres"),
        ODRFontItem(id: "Ouvrieres-soldates", fileName: "Ouvrieres-soldates.ttf", postScriptName: "Ouvrieres-soldates", displayName: "Ouvrieres Soldates", familyName: "Ouvrieres", odrTag: "Fonts.Ouvrieres"),
        ODRFontItem(id: "Rubik-Storm-Regular", fileName: "Rubik-Storm-Regular.ttf", postScriptName: "Rubik-Storm-Regular", displayName: "Rubik Storm", familyName: "Rubik", odrTag: "Fonts.Rubik"),
        ODRFontItem(id: "Rubik-Vinyl-Regular", fileName: "Rubik-Vinyl-Regular.ttf", postScriptName: "Rubik-Vinyl-Regular", displayName: "Rubik Vinyl", familyName: "Rubik", odrTag: "Fonts.Rubik"),
        ODRFontItem(id: "Rubik-WetPaint-Regular", fileName: "Rubik-WetPaint-Regular.ttf", postScriptName: "Rubik-WetPaint-Regular", displayName: "Rubik Wet Paint", familyName: "Rubik", odrTag: "Fonts.Rubik"),
        ODRFontItem(id: "TiejiliSC-Regular", fileName: "TiejiliSC-Regular.otf", postScriptName: "TiejiliSC-Regular", displayName: "铁蒺藜", familyName: "铁蒺藜", odrTag: "Fonts.Tiejili"),
        ODRFontItem(id: "VictorMono-Bold", fileName: "VictorMono-Bold.ttf", postScriptName: "VictorMono-Bold", displayName: "Victor Mono 粗体", familyName: "Victor Mono", odrTag: "Fonts.VictorMono"),
        ODRFontItem(id: "VictorMono-ExtraLight", fileName: "VictorMono-ExtraLight.ttf", postScriptName: "VictorMono-ExtraLight", displayName: "Victor Mono 极细", familyName: "Victor Mono", odrTag: "Fonts.VictorMono"),
        ODRFontItem(id: "VictorMono-Light", fileName: "VictorMono-Light.ttf", postScriptName: "VictorMono-Light", displayName: "Victor Mono 细体", familyName: "Victor Mono", odrTag: "Fonts.VictorMono"),
        ODRFontItem(id: "VictorMono-Medium", fileName: "VictorMono-Medium.ttf", postScriptName: "VictorMono-Medium", displayName: "Victor Mono 中等", familyName: "Victor Mono", odrTag: "Fonts.VictorMono"),
        ODRFontItem(id: "VictorMono-Regular", fileName: "VictorMono-Regular.ttf", postScriptName: "VictorMono-Regular", displayName: "Victor Mono 常规", familyName: "Victor Mono", odrTag: "Fonts.VictorMono"),
        ODRFontItem(id: "VictorMono-ThinItalic", fileName: "VictorMono-ThinItalic.ttf", postScriptName: "VictorMono-ThinItalic", displayName: "Victor Mono 细斜体", familyName: "Victor Mono", odrTag: "Fonts.VictorMono"),
        ODRFontItem(id: "YuFanXinYu-Bold", fileName: "YuFanXinYu-Bold.ttf", postScriptName: "YuFanXinYu-Bold", displayName: "余繁新语 粗体", familyName: "余繁新语", odrTag: "Fonts.YuFanXinYu"),
        ODRFontItem(id: "YuFanXinYu-Light", fileName: "YuFanXinYu-Light.ttf", postScriptName: "YuFanXinYu-Light", displayName: "余繁新语 细体", familyName: "余繁新语", odrTag: "Fonts.YuFanXinYu"),
        ODRFontItem(id: "YuFanXinYu-Medium", fileName: "YuFanXinYu-Medium.ttf", postScriptName: "YuFanXinYu-Medium", displayName: "余繁新语 中等", familyName: "余繁新语", odrTag: "Fonts.YuFanXinYu"),
        ODRFontItem(id: "YuFanXinYu-Regular", fileName: "YuFanXinYu-Regular.ttf", postScriptName: "YuFanXinYu-Regular", displayName: "余繁新语 常规", familyName: "余繁新语", odrTag: "Fonts.YuFanXinYu"),
        ODRFontItem(id: "fusion-pixel-10px-proportional", fileName: "fusion-pixel-10px-proportional.otf", postScriptName: "Fusion-Pixel-10px-Proportional-Regular", displayName: "Fusion Pixel 10px", familyName: "Fusion Pixel 10px", odrTag: "Fonts.FusionPixel10Prop"),
        ODRFontItem(id: "poorhandwriting", fileName: "poorhandwriting.ttf", postScriptName: "Poorhandwriting", displayName: "Poor Handwriting", familyName: "Poor Handwriting", odrTag: "Fonts.PoorHandwriting"),
        ODRFontItem(id: "中文像素字体-圆点", fileName: "中文像素字体-圆点.otf", postScriptName: "DottedSongtiCircleRegular", displayName: "中文像素字体 圆点", familyName: "中文像素字体", odrTag: "Fonts.CNPixel"),
        ODRFontItem(id: "中文像素字体-方点", fileName: "中文像素字体-方点.otf", postScriptName: "DottedSongtiSquareRegular", displayName: "中文像素字体 方点", familyName: "中文像素字体", odrTag: "Fonts.CNPixel"),
        ODRFontItem(id: "也字工厂小石头", fileName: "也字工厂小石头.ttf", postScriptName: "YEFONTXiaoShiTou", displayName: "也字工厂小石头", familyName: "也字工厂小石头", odrTag: "Fonts.YeZiXiaoShiTou"),
        ODRFontItem(id: "乡立方黑体", fileName: "乡立方黑体.ttf", postScriptName: "xianglifang-Regular", displayName: "乡立方黑体", familyName: "乡立方黑体", odrTag: "Fonts.XiangLiFang"),
        ODRFontItem(id: "云峰寒蝉体", fileName: "云峰寒蝉体.ttf", postScriptName: "font00000000301902d5", displayName: "云峰寒蝉体", familyName: "云峰寒蝉体", odrTag: "Fonts.YunFengHanChan"),
        ODRFontItem(id: "今年也要加油鸭", fileName: "今年也要加油鸭.ttf", postScriptName: "SJjnyyjyy", displayName: "今年也要加油鸭", familyName: "今年也要加油鸭", odrTag: "Fonts.JiaYouYa"),
        ODRFontItem(id: "仓耳非白W01", fileName: "仓耳非白W01.ttf", postScriptName: "TsangerFeiBai-W01", displayName: "仓耳非白 极细", familyName: "仓耳非白", odrTag: "Fonts.CangErFeiBai"),
        ODRFontItem(id: "仓耳非白W02", fileName: "仓耳非白W02.ttf", postScriptName: "TsangerFeiBai-W02", displayName: "仓耳非白 细体", familyName: "仓耳非白", odrTag: "Fonts.CangErFeiBai"),
        ODRFontItem(id: "仓耳非白W03", fileName: "仓耳非白W03.ttf", postScriptName: "TsangerFeiBai-W03", displayName: "仓耳非白 常规", familyName: "仓耳非白", odrTag: "Fonts.CangErFeiBai"),
        ODRFontItem(id: "仓耳非白W04", fileName: "仓耳非白W04.ttf", postScriptName: "TsangerFeiBai-W04", displayName: "仓耳非白 半粗", familyName: "仓耳非白", odrTag: "Fonts.CangErFeiBai"),
        ODRFontItem(id: "仓耳非白W05", fileName: "仓耳非白W05.ttf", postScriptName: "TsangerFeiBai-W05", displayName: "仓耳非白 粗体", familyName: "仓耳非白", odrTag: "Fonts.CangErFeiBai"),
        ODRFontItem(id: "千图小兔体", fileName: "千图小兔体.ttf", postScriptName: "QTxiaotu", displayName: "千图小兔体", familyName: "千图小兔体", odrTag: "Fonts.QianTuXiaoTu"),
        ODRFontItem(id: "南构无恙行书", fileName: "南构无恙行书.ttf", postScriptName: "nangouwuyangxingshu", displayName: "南构无恙行书", familyName: "南构无恙行书", odrTag: "Fonts.NanGouWuYang"),
        ODRFontItem(id: "南西初夏宋-简繁", fileName: "南西初夏宋-简繁.ttf", postScriptName: "NanxiChuxiasong-Regualr", displayName: "南西初夏宋", familyName: "南西初夏宋", odrTag: "Fonts.NanXiChuXia"),
        ODRFontItem(id: "呆萌手写体", fileName: "呆萌手写体.otf", postScriptName: "Dymon-ShouXieTi", displayName: "呆萌手写体", familyName: "呆萌手写体", odrTag: "Fonts.DaiMeng"),
        ODRFontItem(id: "墨趣古风体", fileName: "墨趣古风体.ttf", postScriptName: "MoQuGuFengTi", displayName: "墨趣古风体", familyName: "墨趣古风体", odrTag: "Fonts.MoQuGuFeng"),
        ODRFontItem(id: "她屿山海", fileName: "她屿山海.ttf", postScriptName: "TaYuShanHai", displayName: "她屿山海", familyName: "她屿山海", odrTag: "Fonts.TaYuShanHai"),
        ODRFontItem(id: "字制区喜脉喜欢体", fileName: "字制区喜脉喜欢体.ttf", postScriptName: "xihuanti", displayName: "字制区喜脉喜欢体", familyName: "字制区喜脉喜欢体", odrTag: "Fonts.ZiZhiQuXiMai"),
        ODRFontItem(id: "小可奶酪体", fileName: "小可奶酪体.ttf", postScriptName: "ZQKNLT-Regular", displayName: "小可奶酪体", familyName: "小可奶酪体", odrTag: "Fonts.XiaoKeNaiLao"),
        ODRFontItem(id: "快看世界体", fileName: "快看世界体.ttf", postScriptName: "kuaikanshijieti", displayName: "快看世界体", familyName: "快看世界体", odrTag: "Fonts.KuaiKan"),
        ODRFontItem(id: "抖音美好体", fileName: "抖音美好体.otf", postScriptName: "DOUYINSANSBOLD-GB", displayName: "抖音美好体", familyName: "抖音美好体", odrTag: "Fonts.DouYinMeiHao"),
        ODRFontItem(id: "文心喜乐体", fileName: "文心喜乐体.ttf", postScriptName: "WenxinXileFont", displayName: "文心喜乐体", familyName: "文心喜乐体", odrTag: "Fonts.WenxinXile"),
        ODRFontItem(id: "新叶念体", fileName: "新叶念体.otf", postScriptName: "-Regular", displayName: "新叶念体", familyName: "新叶念体", odrTag: "Fonts.XinYeNian"),
        ODRFontItem(id: "明达明达无锋体", fileName: "明达明达无锋体.ttf", postScriptName: "MDMD-WuFengTi", displayName: "明达明达无锋体", familyName: "明达明达无锋体", odrTag: "Fonts.MingDaWuFeng"),
        ODRFontItem(id: "栗壳坚坚体", fileName: "栗壳坚坚体.ttf", postScriptName: "LikeJianJianTi-Regular", displayName: "栗壳坚坚体", familyName: "栗壳坚坚体", odrTag: "Fonts.LiKeJianJian"),
        ODRFontItem(id: "猫啃珠圆体 MaokenZhuyuanTi", fileName: "猫啃珠圆体 MaokenZhuyuanTi.ttf", postScriptName: "MaokenZhuyuanTi-Regular", displayName: "猫啃珠圆体", familyName: "猫啃珠圆体", odrTag: "Fonts.MaoKenZhuyuan"),
        ODRFontItem(id: "白路俏丽手写体", fileName: "白路俏丽手写体.ttf", postScriptName: "bailuqiaolishouxieti", displayName: "白路俏丽手写体", familyName: "白路俏丽手写体", odrTag: "Fonts.BaiLuQiaoLi"),
        ODRFontItem(id: "簡語生活體", fileName: "簡語生活體.ttf", postScriptName: "AbbrFesFont", displayName: "簡語生活體", familyName: "簡語生活體", odrTag: "Fonts.JianYuShengHuo"),
        ODRFontItem(id: "精品点阵体", fileName: "精品点阵体.ttf", postScriptName: "BoutiqueBitmap9x9_1.9_R", displayName: "精品点阵体", familyName: "精品点阵体", odrTag: "Fonts.BoutiqueBitmap"),
        ODRFontItem(id: "精品点阵体_Bold", fileName: "精品点阵体_Bold.ttf", postScriptName: "BoutiqueBitmap9x9_1.9_B", displayName: "精品点阵体 粗体", familyName: "精品点阵体", odrTag: "Fonts.BoutiqueBitmap"),
        ODRFontItem(id: "草书(简入繁出)", fileName: "草书(简入繁出).ttf", postScriptName: "CaoShuSimp2Trad-regular", displayName: "草书", familyName: "草书", odrTag: "Fonts.CaoShu"),
        ODRFontItem(id: "荷塘月色手写体+Regular", fileName: "荷塘月色手写体+Regular.ttf", postScriptName: "font00000000301902d5", displayName: "荷塘月色手写体", familyName: "荷塘月色手写体", odrTag: "Fonts.HeTangYueSe"),
        ODRFontItem(id: "重庆山城棒棒体", fileName: "重庆山城棒棒体.ttf", postScriptName: "YunFengchongqingbangbangti", displayName: "重庆山城棒棒体", familyName: "重庆山城棒棒体", odrTag: "Fonts.ChongQingBangBang"),
        ODRFontItem(id: "阿朱泡泡体", fileName: "阿朱泡泡体.ttf", postScriptName: "AZPPT_1_1436212_19", displayName: "阿朱泡泡体", familyName: "阿朱泡泡体", odrTag: "Fonts.AZhuPaoPao"),
        ODRFontItem(id: "鸿雷小纸条青春体", fileName: "鸿雷小纸条青春体.ttf", postScriptName: "HongleiXiaozhitiao_qingchunti", displayName: "鸿雷小纸条青春体", familyName: "鸿雷小纸条青春体", odrTag: "Fonts.HongLei"),
        ODRFontItem(id: "鼎猎西大体", fileName: "鼎猎西大体.ttf", postScriptName: "dingliexidafont", displayName: "鼎猎西大体", familyName: "鼎猎西大体", odrTag: "Fonts.DingLieXiDa"),
    ]

    private static var familySortIndex: [String: Int] {
        var map: [String: Int] = [:]
        for (i, name) in freeFamilyNames.enumerated() {
            map[name] = i
        }
        let freeCount = freeFamilyNames.count
        for (i, name) in proFamilyOrder.enumerated() {
            map[name] = freeCount + i
        }
        return map
    }

    static var families: [(name: String, fonts: [ODRFontItem])] {
        let grouped = Dictionary(grouping: all, by: \.familyName)
        let index = familySortIndex
        return grouped.map { (name: $0.key, fonts: $0.value) }
            .sorted { a, b in
                let ia = index[a.name] ?? Int.max
                let ib = index[b.name] ?? Int.max
                if ia != ib { return ia < ib }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
    }

    static var allTags: Set<String> { Set(all.map(\.odrTag)) }

    static func item(id: String) -> ODRFontItem? { all.first { $0.id == id } }
    static func items(tag: String) -> [ODRFontItem] { all.filter { $0.odrTag == tag } }
}
