////
////  MinApp.swift
////  Min
////
////  Created by KangXiang on 2024/12/30
////
//
import SwiftUI
import SwiftData
import WidgetKit
import ContactsUI

@main
struct MinApp: App {
    init() {
        // 启动时注册 App Group 内已下载的自定义字体
        _ = ODRFontManager.shared
        // 预热 WKWebView，消除隐私政策/用户协议首次打开的 2-3 秒冷启动延迟
        WebViewPool.shared.warmUp()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])

        // 提前创建 Application Support，避免 SwiftData 首次启动刷屏 CoreData errno 2
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        if let appSupport {
            try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        }

        // 明确不放入 App Group：避免与 Widget 共享容器冲突
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("创建 ModelContainer 时出错： \(error)")
            do {
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, groupContainer: .none)
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("严重错误：即使使用内存回退，也无法创建 ModelContainer： \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MinDeepLinkHost()
                .environmentObject(SubscriptionManager.shared)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    /// 处理从小组件传入的URL
    private func handleDeepLink(_ url: URL) {
        print("收到URL: \(url.absoluteString)")
        
        if url.scheme == "min" {
            switch url.host {
            case "weather":
                openWeatherAppAndRefresh()
                return
            case "phone":
                openPhoneApp()
                return
            case "contacts":
                openContactsApp()
                return
            default:
                break
            }
        }
        
        let scheme = url.scheme ?? ""
        print("尝试打开URL Scheme: \(scheme)")
        
        // 直接尝试打开（部分场景下 canOpenURL 在冷启动/早期阶段可能返回 false）
        openExternalURL(url)
    }
    
    /// 电话没有可公开注册的「打开 App」scheme，`mobilephone://` 会被系统拦截。
    /// `tel://` 是 Apple 文档中的公开地址，能拉起电话应用。
    private func openPhoneApp() {
        openFirstAvailable(urls: ["tel://", "telprompt://"])
    }
    
    /// 通讯录没有稳定公开 scheme，打开系统联系人选择器（不需要通讯录权限）。
    private func openContactsApp() {
        DispatchQueue.main.async {
            DeepLinkCenter.shared.presentContactsPicker = true
        }
    }
    
    private func openFirstAvailable(urls: [String], onFailure: (() -> Void)? = nil) {
        func tryAt(_ index: Int) {
            guard index < urls.count, let url = URL(string: urls[index]) else {
                onFailure?()
                return
            }
            UIApplication.shared.open(url) { success in
                print("打开 \(urls[index])：\(success ? "成功" : "失败")")
                if !success {
                    tryAt(index + 1)
                }
            }
        }
        tryAt(0)
    }
    
    private func openWeatherAppAndRefresh() {
        if let weatherURL = URL(string: "weather://") {
            openExternalURL(weatherURL)
        }
        
        Task {
            let result = await WeatherCache.forceRefresh()
            switch result {
            case .success:
                print("天气小组件点击：手动刷新成功")
                WidgetCenter.shared.reloadTimelines(ofKind: "MinTopWidget")
            case .cooldown(let remaining):
                print("天气小组件点击：手动刷新冷却中，剩余 \(Int(ceil(remaining))) 秒")
            case .failed:
                print("天气小组件点击：手动刷新失败")
            }
        }
    }
    
    private func openExternalURL(_ url: URL) {
        UIApplication.shared.open(url) { success in
            print("打开目标应用：\(success ? "成功" : "失败")")
            
            if !success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    print("重试打开URL: \(url)")
                    UIApplication.shared.open(url) { retrySuccess in
                        print("重试打开结果: \(retrySuccess ? "成功" : "仍然失败")")
                        if !retrySuccess {
                            print("❌ 两次尝试均失败：\(url)")
                            print("已注册的URL schemes: \(Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") ?? "无")")
                        }
                    }
                }
            }
        }
    }
}

final class DeepLinkCenter: ObservableObject {
    static let shared = DeepLinkCenter()
    @Published var presentContactsPicker = false
}

private struct MinDeepLinkHost: View {
    @ObservedObject private var deepLink = DeepLinkCenter.shared
    @Query private var items: [Item]

    var body: some View {
        MinRootView()
            .sheet(isPresented: $deepLink.presentContactsPicker) {
                ContactPickerView()
            }
            .onAppear {
                remapBrokenSystemAppURLs()
            }
    }

    /// 把已经添加、但打不开的电话/通讯录地址改成可用入口。
    private func remapBrokenSystemAppURLs() {
        let phoneBroken: Set<String> = [
            "mobilephone://",
            "mobilephone-recents://",
            "mobilephone-contacts://",
            "mobilephone-favorites://"
        ]
        let contactsBroken: Set<String> = [
            "contact://",
            "contacts://",
            "people://"
        ]

        var changed = false
        for item in items {
            if phoneBroken.contains(item.url) {
                item.url = "min://phone"
                changed = true
            } else if contactsBroken.contains(item.url) {
                item.url = "min://contacts"
                changed = true
            }
        }

        if changed {
            AppGroupStore.setCodable(items.map { WidgetItem.fromItem($0) }, forKey: "widgetItems")
            AppGroupStore.reloadWidgetsDebounced()
        }
    }
}

private struct ContactPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            dismiss()
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            dismiss()
        }
    }
}
