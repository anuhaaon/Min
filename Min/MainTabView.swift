//
//  MainTabView.swift
//  Min
//
//  首页 / 个性化 / 我的；iOS 18+ 使用 .sidebarAdaptable（含 iOS 26 液体玻璃）。图标未选 outline、选中 .fill 由 tabItem + symbolVariants 从首帧正确显示。
//

import SwiftUI
import SwiftData
import StoreKit
import UIKit
import WidgetKit

/// 三个 Tab：rawValue 为未选图标名，选中时用 rawValue + ".fill"
enum MinTab: String, CaseIterable {
    case home = "house"
    case personalize = "square.grid.2x2"
    case mine = "person"
    var fillImageName: String { rawValue + ".fill" }
}

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var fontSetting = FontSetting()
    @State private var selectedAlignment: TextAlignmentView.TextAlignment = .leading

    private func tabItemImage(tab: MinTab, tag: Int) -> some View {
        Image(systemName: selectedTab == tag ? tab.fillImageName : tab.rawValue)
            .font(.system(size: 15))
            .environment(\.symbolVariants, .none)
    }

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: $selectedTab) {
                    ContentView(
                        selectedAlignment: $selectedAlignment,
                        fontSetting: $fontSetting
                    )
                    .tag(0)
                    .tabItem { tabItemImage(tab: .home, tag: 0) }

                    SettingView(
                        selectedAlignment: $selectedAlignment,
                        fontSetting: $fontSetting
                    )
                    .tag(1)
                    .tabItem { tabItemImage(tab: .personalize, tag: 1) }

                    MineView()
                    .tag(2)
                    .tabItem { tabItemImage(tab: .mine, tag: 2) }
                }
                .tabViewStyle(.sidebarAdaptable)
                .tint(.white)
                .background(Color.black)
                .toolbarBackground(Color.black, for: .tabBar)
            } else {
                TabView(selection: $selectedTab) {
                    ContentView(
                        selectedAlignment: $selectedAlignment,
                        fontSetting: $fontSetting
                    )
                    .tag(0)
                    .tabItem { tabItemImage(tab: .home, tag: 0) }

                    SettingView(
                        selectedAlignment: $selectedAlignment,
                        fontSetting: $fontSetting
                    )
                    .tag(1)
                    .tabItem { tabItemImage(tab: .personalize, tag: 1) }

                    MineView()
                    .tag(2)
                    .tabItem { tabItemImage(tab: .mine, tag: 2) }
                }
                .tint(.white)
                .background(Color.black)
                .toolbarBackground(Color.black, for: .tabBar)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadSettingsFromSharedContainer()
        }
        // 在 Tab 根层保存，避免切到个性化页时 ContentView 未挂载导致设置不同步到小组件
        .onChange(of: fontSetting) { _, _ in
            saveSettingsToSharedContainer()
        }
        .onChange(of: selectedAlignment) { _, _ in
            saveSettingsToSharedContainer()
        }
    }

    private func loadSettingsFromSharedContainer() {
        let decoder = JSONDecoder()
        if let data = AppGroupStore.data(forKey: "fontSetting"),
           let saved = try? decoder.decode(FontSetting.self, from: data) {
            fontSetting = saved
        }
        if let data = AppGroupStore.data(forKey: "textAlignment"),
           let saved = try? decoder.decode(TextAlignmentType.self, from: data) {
            switch saved {
            case .leading: selectedAlignment = .leading
            case .center: selectedAlignment = .center
            case .trailing: selectedAlignment = .trailing
            }
        }
    }

    private func saveSettingsToSharedContainer() {
        let encoder = JSONEncoder()
        do {
            // 防止内存态缺背景图时把磁盘里已有壁纸冲掉
            var settingToSave = fontSetting
            if settingToSave.backgroundImageName == nil,
               let data = AppGroupStore.data(forKey: "fontSetting"),
               let existing = try? JSONDecoder().decode(FontSetting.self, from: data),
               let bg = existing.backgroundImageName {
                settingToSave.backgroundImageName = bg
            }

            let fontSettingData = try encoder.encode(settingToSave)
            AppGroupStore.set(fontSettingData, forKey: "fontSetting")

            let textAlignment: TextAlignmentType
            switch selectedAlignment {
            case .leading: textAlignment = .leading
            case .center: textAlignment = .center
            case .trailing: textAlignment = .trailing
            }
            let alignmentData = try encoder.encode(textAlignment)
            AppGroupStore.set(alignmentData, forKey: "textAlignment")
            AppGroupStore.reloadWidgetsDebounced()
        } catch {
            print("MainTabView: 保存设置到 App Group 失败: \(error)")
        }
    }
}

struct MineView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @EnvironmentObject private var subscription: SubscriptionManager
    @State private var showFeedbackAlert = false
    @State private var feedbackText = ""
    @State private var showPaywall = false
    @State private var showShareSheet = false
    @State private var webSheetURL: URL? = nil
    
    private var isMember: Bool { subscription.isPro }
    
    private let aboutURL = "https://min.anuhao.com"
    private let privacyPolicyURL = "https://min.anuhao.com/privacy-policy"
    private let termsOfServiceURL = "https://min.anuhao.com/terms-of-service"
    /// 上架后到 App Store Connect → App 信息 复制「Apple ID」填到这里（纯数字）。未填写时评分走系统弹窗。
    private let appStoreID: String? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Color.clear.frame(height: 20)
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        profileSection
                        membershipSection
                        
                        VStack(alignment: .leading, spacing: 6) {
                            SettingSectionHeader(title: "支持")
                            supportItems
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            SettingSectionHeader(title: "关于")
                            aboutItems
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
                .overlay(alignment: .top) {
                    MinEdgeFade(edge: .top, height: 25)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showFeedbackAlert) {
            FeedbackSheetView(feedbackText: $feedbackText)
                .minNativeSheet(detents: [.height(FeedbackSheetView.preferredSheetHeight)])
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscription)
                .minNativeSheet(detents: [.large])
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
                .minNativeSheet(detents: [.medium])
        }
        .sheet(item: $webSheetURL) { url in
            WebSheetView(url: url)
                .minNativeSheet(detents: [.large])
        }
    }
    
    private var shareItems: [Any] {
        var items: [Any] = ["推荐你试试 Min — 极简桌面小组件"]
        if let id = appStoreID, !id.isEmpty,
           let storeURL = URL(string: "https://apps.apple.com/app/id\(id)") {
            items.append(storeURL)
        } else if let site = URL(string: aboutURL) {
            items.append(site)
        }
        return items
    }
    
    private var profileSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Min")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }
    
    private var membershipSection: some View {
        Button {
            showPaywall = true
        } label: {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isMember ? 0.14 : 0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
                    .frame(height: 72)
                
                HStack(spacing: 0) {
                    Image(systemName: isMember ? "crown.fill" : "crown")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.leading, 28)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isMember ? "已开通会员" : "订阅会员")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(isMember ? "尊享全部功能" : "解锁高级特性")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.leading, 12)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(isMember ? "管理" : "开通")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.trailing, 28)
                }
                .frame(height: 72)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var supportItems: some View {
        VStack(spacing: 10) {
            MineMenuItem(icon: "envelope", title: "意见反馈") {
                showFeedbackAlert = true
            }
            
            MineMenuItem(icon: "star", title: "给个评分") {
                requestAppRating()
            }
            
            MineMenuItem(icon: "share", title: "分享给朋友") {
                showShareSheet = true
            }
        }
    }
    
    private var aboutItems: some View {
        VStack(spacing: 10) {
            MineMenuItem(icon: "info.circle", title: "关于我们") {
                if let url = URL(string: aboutURL) { openURL(url) }
            }
            
            MineMenuItem(icon: "shield", title: "隐私政策") {
                webSheetURL = URL(string: privacyPolicyURL)
            }
            
            MineMenuItem(icon: "doc.text", title: "用户协议") {
                webSheetURL = URL(string: termsOfServiceURL)
            }
        }
    }
    
    /// 未上架：系统评分弹窗；上架后填好 appStoreID 会跳转 App Store 写评价页
    private func requestAppRating() {
        if let id = appStoreID, !id.isEmpty,
           let url = URL(string: "https://apps.apple.com/app/id\(id)?action=write-review") {
            openURL(url)
        } else {
            requestReview()
        }
    }
}

private struct SettingSectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(.white.opacity(0.4))
            .padding(.leading, 4)
    }
}

private struct MineMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 20)
                    .foregroundStyle(Color.gray.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                    .frame(height: 60)
                
                HStack(spacing: 0) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(.leading, 28)
                    
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.leading, 10)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.trailing, 28)
                }
                .frame(height: 60)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 意见反馈 Sheet

private struct FeedbackSheetView: View {
    @Binding var feedbackText: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    private static let gap = MinSettingChrome.sheetChromeGap
    private static let editorHeight: CGFloat = 120
    private static let buttonHeight: CGFloat = 48
    static var preferredSheetHeight: CGFloat {
        gap + editorHeight + gap + buttonHeight + gap
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: MinSettingChrome.corner, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: MinSettingChrome.corner, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                if feedbackText.isEmpty {
                    Text("反馈、建议、Bug 都可以写在这里…")
                        .foregroundStyle(.white.opacity(0.25))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }

                TextEditor(text: $feedbackText)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .font(.system(size: 15))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($isFocused)
            }
            .frame(height: Self.editorHeight)
            .padding(.horizontal, MinSettingChrome.contentInset)
            .padding(.top, Self.gap)
            .padding(.bottom, Self.gap)

            Button {
                let body = feedbackText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                let subject = "Min App 意见反馈".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                if let url = URL(string: "mailto:anuhaaon@163.com?subject=\(subject)&body=\(body)") {
                    UIApplication.shared.open(url)
                }
                feedbackText = ""
                dismiss()
            } label: {
                Text("提交反馈")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.buttonHeight)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: MinSettingChrome.corner, style: .continuous))
            }
            .padding(.horizontal, MinSettingChrome.contentInset)
            .padding(.bottom, Self.gap)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.clear)
    }
}

// MARK: - 系统分享面板

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MainTabView()
        .environmentObject(SubscriptionManager.shared)
        .modelContainer(for: Item.self, inMemory: true)
}
