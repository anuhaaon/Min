//
//  ContentView.swift
//  Min
//
//  Created by KangXiang on 2024/12/30.
//

import SwiftUI
import SwiftData
import WidgetKit
import BigUIPaging
import UIKit

// 创建一个符合Identifiable的类型用于传递给sheet
struct GroupSelection: Identifiable {
    let id = UUID()
    let group: Int
}

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var subscription: SubscriptionManager
    @Query(sort: [SortDescriptor(\Item.group), SortDescriptor(\Item.order)])
    var items: [Item]
    
    @Binding var selectedAlignment: TextAlignmentView.TextAlignment
    @Binding var fontSetting: FontSetting
    
    @State private var selectedGroupForSheet: GroupSelection? = nil
    @State private var selection: Int = 0
    /// 卡片内当前正在编辑名称的 item id，打开设置或切换页面时清空以自动退出编辑
    @State private var cardEditingItemId: UUID? = nil
    /// 当前卡片在屏幕中的 frame（用于编辑时透明层不遮挡卡片，使删除按钮可点）
    @State private var cardFrameInGlobal: CGRect = .zero
    @State private var showPaywall = false

	    // App Group suite name for sharing with widget and persistence across launches
	    // 统一走 AppGroupStore，勿再新建 UserDefaults(suiteName:) + synchronize
    
    var body: some View {
        ZStack {
            // 最底层全屏黑底，覆盖安全区与上下弧度区域，保持全黑
            Color.black
                .ignoresSafeArea(.container, edges: .bottom)
            NavigationStack {
                ZStack {
                    Color.black
                        .ignoresSafeArea(.container, edges: .bottom)
                    // 编辑时：先放「仅卡片外可点」的层（在背后），再放主内容，卡片在上层可直接收到删除按钮点击
                    if cardEditingItemId != nil {
                        editingDismissOverlay(cardFrame: cardFrameInGlobal) {
                            cardEditingItemId = nil
                        }
                    }
                    VStack(spacing: 0) {
                        // 顶部 M：固定高度且忽略键盘，键盘弹出时保持不动（设置已移至 Tab「个性化」）
                        ZStack {
                            Color.clear
                            Image("BrandIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120, alignment: .center)
                                .offset(y: 45)
                        }
                        .frame(height: 136)
                        .contentShape(Rectangle())
                        .ignoresSafeArea(.keyboard)

                        // 卡片区域：仅 CRUD 数据，样式不与设置同步；小组件预览与桌面 LargeWidget 在设置页同步
                        CardDeckView(
                            selection: $selection,
                            items: items,
                            editingItemId: $cardEditingItemId,
                            onAddItem: { group in
                                let hasItems = items.contains { $0.group == group }
                                if subscription.canUseCard(group: group, hasExistingItems: hasItems) {
                                    selectedGroupForSheet = GroupSelection(group: group)
                                } else {
                                    showPaywall = true
                                }
                            }
                        )
                        .padding(.vertical)
                        .onPreferenceChange(CardDeckView.CardFramePreferenceKey.self) { newFrame in
                            cardFrameInGlobal = newFrame
                        }
                    }
                }
                .sheet(item: $selectedGroupForSheet) { selection in
                    SearchView(targetGroup: selection.group)
                        .id(UUID())
                        .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                        .environmentObject(subscription)
                        .minNativeSheet(detents: [.large])
                }
            }
        }
            .onChange(of: selectedAlignment) { _, _ in
                saveDataToSharedContainer()
            }
            .onChange(of: fontSetting) { _, newValue in
                saveDataToSharedContainer()
                if newValue.topWidgetType == .weather {
                    fetchAndSaveWeatherToSharedContainerIfNeeded()
                }
            }
            .onChange(of: items.map(\.persistentModelID)) { _, _ in
                saveDataToSharedContainer()
            }
            .onAppear {
                loadDataFromSharedContainer()
                saveDataToSharedContainer()
                fetchAndSaveWeatherToSharedContainerIfNeeded()
            }
            .onChange(of: scenePhase, initial: false) { _, newPhase in
                // 回到前台时再次写入并刷新小组件，避免刚添加到桌面时扩展进程未读到最新数据
                if newPhase == .active {
                    saveDataToSharedContainer()
                    // 天气尚无真实定位时，回前台继续尝试
                    if fontSetting.topWidgetType == .weather,
                       WeatherCache.usableSnapshot() == nil {
                        fetchAndSaveWeatherToSharedContainerIfNeeded()
                    }
                }
            }
        }
    
    
    
    /// 编辑时仅在卡片外显示可点击层，点击即退出编辑；卡片区域不遮挡，删除按钮可点
    private func editingDismissOverlay(cardFrame: CGRect, onDismiss: @escaping () -> Void) -> some View {
        GeometryReader { geo in
            let selfFrame = geo.frame(in: .global)
            let cardInLocal = CGRect(
                x: cardFrame.minX - selfFrame.minX,
                y: cardFrame.minY - selfFrame.minY,
                width: cardFrame.width,
                height: cardFrame.height
            )
            if cardFrame != .zero, cardFrame.width >= 10, cardFrame.height >= 10 {
                VStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onDismiss)
                        .frame(width: geo.size.width, height: max(0, cardInLocal.minY))
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onDismiss)
                            .frame(width: max(0, cardInLocal.minX), height: cardInLocal.height)
                        Color.clear
                            .frame(width: max(0, cardInLocal.width), height: cardInLocal.height)
                            .allowsHitTesting(false)
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(perform: onDismiss)
                            .frame(width: max(0, geo.size.width - cardInLocal.maxX), height: cardInLocal.height)
                    }
                    .frame(height: cardInLocal.height)
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onDismiss)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea(.container, edges: .bottom)
                    .onTapGesture(perform: onDismiss)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    // 转换TextAlignmentView.TextAlignment到TextAlignmentType
    private func convertToTextAlignmentType(_ alignment: TextAlignmentView.TextAlignment) -> TextAlignmentType {
        switch alignment {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

	    // 从共享容器加载设置
	    private func loadDataFromSharedContainer() {
	        let decoder = JSONDecoder()
	        
	        // 检查是否是第一次打开（通过检查是否有保存的字体设置）
	        let isFirstLaunch = AppGroupStore.data(forKey: "fontSetting") == nil
	        
	        // 加载字体设置
	        if let fontData = AppGroupStore.data(forKey: "fontSetting"),
	           let savedFontSetting = try? decoder.decode(FontSetting.self, from: fontData) {
	            fontSetting = savedFontSetting
	        } else if isFirstLaunch {
	            // 第一次打开，使用默认值：系统字体，字体大小45
	            fontSetting = FontSetting(
	                fontSize: .custom,
	                customFont: CustomFont(fontName: .system, style: .regular),
	                fontColor: .white,
	                customFontSize: 45,
	                topWidgetType: .empty
	            )
	            // 保存默认设置
	            saveDataToSharedContainer()
	        }
	        
	        // 加载对齐方式
	        if let alignmentData = AppGroupStore.data(forKey: "textAlignment"),
	           let savedAlignment = try? decoder.decode(TextAlignmentType.self, from: alignmentData) {
	            selectedAlignment = convertFromTextAlignmentType(savedAlignment)
	        }
	    }

	    // 将共享类型转换回视图使用的对齐类型
	    private func convertFromTextAlignmentType(_ alignment: TextAlignmentType) -> TextAlignmentView.TextAlignment {
	        switch alignment {
	        case .leading:
	            return .leading
	        case .center:
	            return .center
	        case .trailing:
	            return .trailing
	        }
	    }
	    
	    /// 若当前选择的是天气小组件：无可用真实定位天气、或缓存过期时再请求 WeatherKit
	    private func fetchAndSaveWeatherToSharedContainerIfNeeded() {
	        guard fontSetting.topWidgetType == .weather else { return }
	        WeatherCache.clearFallbackCacheIfNeeded()
	        let cached = WeatherCache.usableSnapshot()
	        // 真定位缓存仍有效：不打 API
	        if WeatherCache.isFresh(cached) { return }
	        Task {
	            let before = WeatherCache.usableSnapshot()?.fetchedAt
	            let snapshot = await WeatherCache.refreshIfNeeded()
	            guard let snapshot, snapshot.isUsable else {
	                print("ContentView: 尚无真实定位天气")
	                return
	            }
	            // 仅在确实刷新成功（时间戳变化）时通知小组件
	            if snapshot.fetchedAt != before {
	                WidgetCenter.shared.reloadTimelines(ofKind: "MinTopWidget")
	            }
	        }
	    }
    
    // 改为internal访问级别，使其可在外部访问
    func saveDataToSharedContainer() {
        let encoder = JSONEncoder()
        do {
            // 保存应用数据（小组件用 [WidgetItem] 解码，须写入该格式）
            // 仅当「本地空 + App Group 已有非空」时跳过，避免冲掉；空覆盖空 / 非空写入都允许
            let widgetItems = items.map { WidgetItem.fromItem($0) }
            let existingItems: [WidgetItem] = {
                guard let data = AppGroupStore.data(forKey: "widgetItems") else { return [] }
                return (try? JSONDecoder().decode([WidgetItem].self, from: data)) ?? []
            }()
            if !widgetItems.isEmpty || existingItems.isEmpty {
                let itemsData = try encoder.encode(widgetItems)
                AppGroupStore.set(itemsData, forKey: "widgetItems")
            }
            
            // 保存字体设置
            let fontSettingData = try encoder.encode(fontSetting)
            AppGroupStore.set(fontSettingData, forKey: "fontSetting")
            
            // 保存对齐方式
            let textAlignment = convertToTextAlignmentType(selectedAlignment)
            let alignmentData = try encoder.encode(textAlignment)
            AppGroupStore.set(alignmentData, forKey: "textAlignment")
            
            AppGroupStore.reloadWidgetsDebounced()
        } catch {
            #if DEBUG
            print("ContentView: 数据保存失败: \(error)")
            #endif
        }
    }

}

// MARK: - Haptic Feedback Helper

/// 触觉反馈辅助类
class HapticFeedbackHelper {
    static let shared = HapticFeedbackHelper()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private init() {
        lightImpact.prepare()
        mediumImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    func light() {
        lightImpact.impactOccurred()
    }
    
    func medium() {
        mediumImpact.impactOccurred()
    }
    
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    func success() {
        notificationFeedback.notificationOccurred(.success)
    }
}

#Preview {
    ContentView(
        selectedAlignment: .constant(.leading),
        fontSetting: .constant(FontSetting())
    )
    .environmentObject(SubscriptionManager.shared)
    .modelContainer(for: Item.self, inMemory: true)
}
