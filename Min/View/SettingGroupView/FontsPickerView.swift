//
//  FontsPickerView.swift
//  Min
//
//  Created by dh on 2025/1/20.
//

import SwiftUI
import UIKit

private func odrDownloadErrorMessage(_ error: Error) -> String {
    let text = error.localizedDescription
    if text.contains("连接") || text.contains("server") || text.lowercased().contains("connect") {
        return "无法连接服务器。请用 Xcode Debug 重新安装 App（本地已嵌入字体包），或检查网络后重试。\n\n\(text)"
    }
    return text
}

// MARK: - 未下载字体预览图（Assets: FontPreviews，由 Scripts/generate_font_previews.swift 生成）

private enum FontPreviewAsset {
    static func imageName(forFamily familyName: String) -> String {
        "FontPreviews/\(slug(familyName))"
    }

    static func uiImage(forFamily familyName: String) -> UIImage? {
        UIImage(named: imageName(forFamily: familyName))
    }

    static func slug(_ text: String) -> String {
        var hash: UInt64 = 5381
        for byte in text.utf8 {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(format: "fp_%016llx", hash)
    }
}

/// 已下载用真字体；未下载用预览图（仍能看到字形）
private struct FontNameLabel: View {
    let title: String
    let familyNameForPreview: String?
    let postScriptName: String?
    let ready: Bool
    var pointSize: CGFloat = 17
    var selected: Bool = false

    private var opacity: Double {
        if selected { return 1 }
        return ready ? 1 : 0.38
    }

    private var renderFont: CustomFont? {
        guard let postScriptName else { return nil }
        let storage = ODRFontCatalog.all.first {
            if let family = familyNameForPreview, $0.familyName != family { return false }
            return $0.postScriptName == postScriptName || $0.displayName == title
        }?.storageFileName
            ?? ODRFontCatalog.all.first { $0.familyName == familyNameForPreview }?.storageFileName
        return CustomFont(
            customFontPostScriptName: postScriptName,
            customFontDisplayName: title,
            customFontStorageFileName: storage
        )
    }

    var body: some View {
        Group {
            if let family = familyNameForPreview,
               let uiImage = FontPreviewAsset.uiImage(forFamily: family) {
                Image(uiImage: uiImage)
                    .resizable()
                    .renderingMode(.template)
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: pointSize * 1.2)
                    .accessibilityLabel(title)
            } else if ready, let renderFont {
                WidgetStyledText(
                    text: title,
                    customFont: renderFont,
                    size: pointSize,
                    color: .white.opacity(opacity),
                    asyncRender: false
                )
            } else {
                Text(title)
                    .font(.system(size: pointSize))
            }
        }
        .foregroundStyle(.white.opacity(opacity))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

// MARK: - 字体家族（一级列表：系统字体 + ODR 自定义字体家族）
enum FontFamilyItem: Identifiable {
    case system(iOSFontName)
    case bundled(familyName: String, fonts: [BundledCustomFont])
    
    var id: String {
        switch self {
        case .system(let name): return "sys-\(name.rawValue)"
        case .bundled(let name, _): return "bundle-\(name)"
        }
    }
    
    var displayName: String {
        switch self {
        case .system(let name): return name.displayName
        case .bundled(let name, _): return name
        }
    }
    
    var isChinese: Bool {
        for scalar in displayName.unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }
    
    var odrTag: String? {
        switch self {
        case .system: return nil
        case .bundled(_, let fonts): return fonts.first?.odrTag
        }
    }
    
    func previewFont(size: CGFloat = 17, ready: Bool) -> Font {
        switch self {
        case .system(.system):
            return .system(size: size)
        case .system(let name):
            return .custom(name.fontName, size: size)
        case .bundled(_, let fonts):
            guard ready, let first = fonts.first else { return .system(size: size) }
            return .custom(first.postScriptName, size: size)
        }
    }
    
    var hasMultipleStyles: Bool {
        switch self {
        case .system: return true
        case .bundled(_, let fonts): return fonts.count > 1
        }
    }
    
    func isSelected(by customFont: CustomFont) -> Bool {
        switch self {
        case .system(let name):
            return customFont.customFontPostScriptName == nil && customFont.fontName == name
        case .bundled(_, let fonts):
            guard let selected = customFont.customFontPostScriptName else { return false }
            return fonts.contains { $0.postScriptName == selected }
        }
    }
}

struct FontsPickerView: View {
    @Binding var customFont: CustomFont
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscription: SubscriptionManager
    @ObservedObject private var odr = ODRFontManager.shared
    @State private var searchText: String = ""
    @State private var downloadError: String?
    @State private var selectingID: String?
    @State private var showPaywall = false
    
    private let haptic = HapticFeedbackHelper.shared
    
    private static let defaultSystemFonts: [iOSFontName] = [.system]
    
    private var familyItems: [FontFamilyItem] {
        let system: [FontFamilyItem] = Self.defaultSystemFonts.map { .system($0) }
        let bundled: [FontFamilyItem] = BundledCustomFonts.families.map { .bundled(familyName: $0.name, fonts: $0.fonts) }
        return system + bundled
    }
    
    private var filteredFamilyItems: [FontFamilyItem] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // 保持目录顺序：系统 → 免费字体 → Pro 字体
        guard !text.isEmpty else { return familyItems }
        return familyItems.filter { $0.displayName.lowercased().contains(text) }
    }

    private func isProLocked(_ item: FontFamilyItem) -> Bool {
        guard case .bundled(let name, _) = item else { return false }
        return !subscription.canUseFontFamily(name)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredFamilyItems) { item in
                        if isProLocked(item) {
                            Button {
                                haptic.light()
                                showPaywall = true
                            } label: {
                                fontFamilyRowLabel(item: item, proLocked: true)
                            }
                            .buttonStyle(.plain)
                        } else if item.hasMultipleStyles {
                            NavigationLink {
                                FontStylePickerView(familyItem: item, customFont: $customFont)
                            } label: {
                                fontFamilyRowLabel(item: item, proLocked: false)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                ensureDownloadedIfNeeded(item: item)
                            })
                        } else {
                            Button {
                                haptic.selection()
                                Task { await selectSingleStyle(item: item) }
                            } label: {
                                fontFamilyRowLabel(item: item, proLocked: false)
                            }
                            .buttonStyle(.plain)
                            .disabled(selectingID == item.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, MinSettingChrome.sheetChromeGap)
                .padding(.bottom, 50)
            }
            .background(Color.clear)
            .navigationTitle("选取字体")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索")
            .alert("下载失败", isPresented: Binding(
                get: { downloadError != nil },
                set: { if !$0 { downloadError = nil } }
            )) {
                Button("好", role: .cancel) {}
            } message: {
                Text(downloadError ?? "")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(subscription)
                    .minNativeSheet(detents: [.large])
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func isReady(_ item: FontFamilyItem) -> Bool {
        guard let tag = item.odrTag else { return true }
        if case .ready = odr.status(for: tag) { return true }
        return false
    }
    
    @ViewBuilder
    private func statusAccessory(for item: FontFamilyItem) -> some View {
        if selectingID == item.id {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white.opacity(0.5))
                .scaleEffect(0.7)
                .frame(width: 18, height: 18)
        } else if let tag = item.odrTag {
            switch odr.status(for: tag) {
            case .ready:
                EmptyView()
            case .downloading(let progress):
                ProgressView(value: progress)
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.5))
                    .scaleEffect(0.7)
                    .frame(width: 18, height: 18)
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.35))
            case .notDownloaded:
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.28))
            }
        }
    }
    
    private func fontFamilyRowLabel(item: FontFamilyItem, proLocked: Bool) -> some View {
        let ready = isReady(item)
        let familyPreviewName: String? = {
            if case .bundled(let name, _) = item { return name }
            return nil
        }()
        let postScript: String? = {
            if case .bundled(_, let fonts) = item { return fonts.first?.postScriptName }
            return nil
        }()
        
        return HStack(spacing: 10) {
            Group {
                switch item {
                case .system:
                    Text(item.displayName)
                        .font(item.previewFont(size: 17, ready: true))
                        .foregroundStyle(.white)
                case .bundled:
                    FontNameLabel(
                        title: item.displayName,
                        familyNameForPreview: familyPreviewName,
                        postScriptName: postScript,
                        ready: ready,
                        pointSize: 17,
                        selected: item.isSelected(by: customFont)
                    )
                }
            }
            Spacer(minLength: 8)
            if proLocked {
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.10))
                    )
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.35))
            } else {
                if item.isSelected(by: customFont) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
                statusAccessory(for: item)
                if item.hasMultipleStyles {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.06))
                .frame(height: 0.5)
        }
        .contentShape(Rectangle())
        .opacity(proLocked ? 0.72 : 1)
    }
    
    private func ensureDownloadedIfNeeded(item: FontFamilyItem) {
        guard !isProLocked(item) else { return }
        guard let tag = item.odrTag else { return }
        if case .ready = odr.status(for: tag) { return }
        if case .downloading = odr.status(for: tag) { return }
        Task {
            do {
                try await odr.ensureDownloaded(tag: tag)
            } catch {
                downloadError = odrDownloadErrorMessage(error)
            }
        }
    }
    
    private func selectSingleStyle(item: FontFamilyItem) async {
        guard !isProLocked(item) else {
            showPaywall = true
            return
        }
        guard case .bundled(_, let fonts) = item, let font = fonts.first else { return }
        guard let odrItem = ODRFontCatalog.item(id: font.id) else { return }
        selectingID = item.id
        defer { selectingID = nil }
        do {
            let result = try await odr.ensureDownloaded(item: odrItem)
            customFont.fontName = .system
            customFont.style = .regular
            customFont.customFontPostScriptName = result.postScriptName
            customFont.customFontDisplayName = font.displayName
            customFont.customFontStorageFileName = result.storageFileName
            dismiss()
        } catch {
            downloadError = odrDownloadErrorMessage(error)
        }
    }
}

// MARK: - 二级页：选取风格
struct FontStylePickerView: View {
    let familyItem: FontFamilyItem
    @Binding var customFont: CustomFont
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscription: SubscriptionManager
    @ObservedObject private var odr = ODRFontManager.shared
    @State private var downloadError: String?
    @State private var showPaywall = false
    
    private let haptic = HapticFeedbackHelper.shared

    private var isProLocked: Bool {
        guard case .bundled(let name, _) = familyItem else { return false }
        return !subscription.canUseFontFamily(name)
    }
    
    private var isReady: Bool {
        guard let tag = familyItem.odrTag else { return true }
        if case .ready = odr.status(for: tag) { return true }
        return false
    }
    
    private var isDownloading: Bool {
        guard let tag = familyItem.odrTag else { return false }
        if case .downloading = odr.status(for: tag) { return true }
        return false
    }
    
    var body: some View {
        Group {
            switch familyItem {
            case .system(let fontName):
                systemStyleList(fontName: fontName)
            case .bundled(_, let fonts):
                bundledStyleList(fonts: fonts)
            }
        }
        .background(Color.clear)
        .navigationTitle("字体粗细")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            guard !isProLocked, let tag = familyItem.odrTag else { return }
            do {
                try await odr.ensureDownloaded(tag: tag)
            } catch {
                downloadError = odrDownloadErrorMessage(error)
            }
        }
        .alert("下载失败", isPresented: Binding(
            get: { downloadError != nil },
            set: { if !$0 { downloadError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(downloadError ?? "")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscription)
                .minNativeSheet(detents: [.large])
        }
        .onAppear {
            if isProLocked {
                showPaywall = true
            }
        }
    }
    
    private func systemStyleList(fontName: iOSFontName) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                Text(fontName.displayName.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .tracking(0.5)
                    .padding(.bottom, 12)
                    .padding(.top, 8)
                
                ForEach(FontStyle.allCases, id: \.self) { style in
                    Button {
                        haptic.selection()
                        customFont.fontName = fontName
                        customFont.style = style
                        customFont.customFontPostScriptName = nil
                        customFont.customFontDisplayName = nil
                        customFont.customFontStorageFileName = nil
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            Text(style.displayName)
                                .font(systemFontForPreview(fontName: fontName, style: style))
                                .foregroundStyle(isSelectedSystem(fontName: fontName, style: style) ? .white : .white.opacity(0.85))
                            Spacer()
                            if isSelectedSystem(fontName: fontName, style: style) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(.white.opacity(0.06))
                                .frame(height: 0.5)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .background(Color.clear)
    }
    
    private func bundledStyleList(fonts: [BundledCustomFont]) -> some View {
        let familyName: String = {
            if case .bundled(let name, _) = familyItem { return name }
            return ""
        }()
        
        return ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                if !familyName.isEmpty {
                    HStack {
                        Text(familyName.uppercased())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                            .tracking(0.5)
                        Spacer()
                        if isDownloading {
                            ProgressView()
                                .tint(.white.opacity(0.5))
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.bottom, 12)
                    .padding(.top, 8)
                }
                
                ForEach(fonts) { font in
                    Button {
                        if isProLocked {
                            haptic.light()
                            showPaywall = true
                            return
                        }
                        guard isReady else { return }
                        haptic.selection()
                        Task {
                            guard let odrItem = ODRFontCatalog.item(id: font.id) else { return }
                            do {
                                let result = try await odr.ensureDownloaded(item: odrItem)
                                customFont.fontName = .system
                                customFont.style = .regular
                                customFont.customFontPostScriptName = result.postScriptName
                                customFont.customFontDisplayName = font.displayName
                                customFont.customFontStorageFileName = result.storageFileName
                                dismiss()
                            } catch {
                                downloadError = odrDownloadErrorMessage(error)
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            FontNameLabel(
                                title: bundledStyleLabel(font.displayName),
                                familyNameForPreview: familyName,
                                postScriptName: font.postScriptName,
                                ready: isReady,
                                pointSize: 17,
                                selected: customFont.customFontPostScriptName == font.postScriptName
                            )
                            Spacer(minLength: 8)
                            if isProLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.35))
                            } else if customFont.customFontPostScriptName == font.postScriptName {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(.white.opacity(0.06))
                                .frame(height: 0.5)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!isProLocked && !isReady)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
        .background(Color.clear)
    }
    
    private func systemFontForPreview(fontName: iOSFontName, style: FontStyle) -> Font {
        if fontName == .system {
            return .system(size: 17, weight: style.fontWeight)
        }
        let f = Font.custom(fontName.fontName, size: 17)
        if style.isItalic { return f.italic() }
        return f.weight(style.fontWeight)
    }
    
    private func isSelectedSystem(fontName: iOSFontName, style: FontStyle) -> Bool {
        customFont.customFontPostScriptName == nil
            && customFont.fontName == fontName
            && customFont.style == style
    }
    
    private func bundledStyleLabel(_ displayName: String) -> String {
        if let lastSpace = displayName.lastIndex(of: " ") {
            return String(displayName[displayName.index(after: lastSpace)...])
        }
        return displayName
    }
}

#Preview {
    FontsPickerView(customFont: .constant(CustomFont()))
        .environmentObject(SubscriptionManager.shared)
}
