# Min

一款深色极简风格的 iOS 个性化启动器：把常用 App、系统功能聚合为首页卡片，通过 URL Scheme 一键直达，并支持桌面小组件与丰富的字体自定义。

<p>
  <img src="https://img.shields.io/badge/iOS-17.0%2B-black" alt="iOS 17.0+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-%E2%9C%93-blue" alt="SwiftUI">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
  <a href="https://apps.apple.com/cn/app/min-极简桌面小组件/id6795857001"><img src="https://img.shields.io/badge/App%20Store-%E5%B7%B2%E4%B8%8A%E6%9E%B6%E5%9B%BD%E5%8C%BA-0D96F6?logo=apple" alt="Download on the App Store"></a>
</p>

## 📲 下载

**App Store（中国大陆区）**：

👉 [Min - 极简桌面小组件](https://apps.apple.com/cn/app/min-极简桌面小组件/id6795857001)

> 源码开源，欢迎 Star / Fork；你也可以直接从 App Store 下载体验完整功能。

## ✨ 功能特性

- **🚀 快捷启动** — 卡片式首页，通过 URL Scheme 打开常用 App 与系统功能；支持应用内搜索 App Store，一键添加应用卡片
- **🧩 桌面小组件** — WidgetKit 小组件展示自定义文字，主 App 通过 App Group 实时同步配置
- **🎨 字体个性化** — 内置 40+ 中英文字体，支持导入自定义字体（按需下载）、字体颜色、对齐方式与背景图
- **💎 Min Pro** — 基于 StoreKit 2 的订阅与买断（月度 / 年度 / 终身），支持恢复购买

## 🛠 技术栈

| 模块 | 技术 |
| --- | --- |
| UI 框架 | SwiftUI |
| 数据持久化 | SwiftData |
| 桌面小组件 | WidgetKit + App Groups |
| 内购 | StoreKit 2 |
| 自定义字体 | On-Demand Resources (ODR) |

## 📦 环境要求与构建

- Xcode 16.0+
- iOS 17.0+ 真机或模拟器
- Apple Developer 账号（小组件需要 App Groups 能力）

```bash
git clone https://github.com/anuhaaon/Min.git
open Min.xcodeproj
```

在 Xcode 中选择 Min scheme，直接 `⌘R` 运行即可。内购使用 `Min/Products.storekit` 本地 StoreKit 配置文件调试，无需连接 App Store Connect。

## 📁 项目结构

```
Min/
├── Min/              # 主 App（视图 / 视图模型 / 模型）
├── MinWidget/        # 桌面小组件扩展
├── Resources/        # 内置字体资源
├── Package/          # 本地依赖
└── Scripts/          # 辅助脚本
```

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源。

内置字体的版权归各自作者所有，仅供学习研究使用，商业使用请查阅对应字体的授权条款。
