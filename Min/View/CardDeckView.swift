//
//  PageIndicatorView.swift
//  Min
//
//  Created by dh on 2025/5/4.
//

import SwiftUI
import BigUIPaging
import SwiftData
import WidgetKit

extension TextAlignmentView.TextAlignment {
    var asAlignment: Alignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}


struct CardDeckView: View {
    @Binding var selection: Int
    var items: [Item]
    /// 当前正在编辑名称的 item id，仅此 id 对应行可编辑；打开设置或切换页面时由外部清空
    @Binding var editingItemId: UUID?
    var onAddItem: (Int) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var subscription: SubscriptionManager
    @State private var showPaywall = false
    
    // 长按进入排序模式的组
    @State private var reorderGroup: Int? = nil
    /// 当前获得焦点的行（用于键盘弹出时滚动到该行，避免被遮挡）
    @State private var focusedItemId: UUID? = nil
    
    /// 对齐桌面 Large Widget：默认字号约 45、行高 50、左右 30、行距约 20（字体仍用系统字）
    private let cardFontSize: CGFloat = 42
    private let cardRowHeight: CGFloat = 50
    private let cardHorizontalPadding: CGFloat = 30
    private let cardRowSpacing: CGFloat = 20
    private let cardVerticalInset: CGFloat = 16
    /// 编辑时冻结为「未编辑时」的卡片边长，仅整体上移不缩卡片
    @State private var storedCardSide: CGFloat?
    
    private struct CardSideKey: PreferenceKey {
        static var defaultValue: CGFloat { 0 }
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }
    
    /// 卡片边长有效阈值，避免 layout 过渡时拿到 0 导致卡片消失
    private let minValidCardSide: CGFloat = 200
    
    /// 用于向父视图上报当前卡片在屏幕中的 frame，以便编辑时透明层不遮挡卡片（删除按钮可点）
    struct CardFramePreferenceKey: PreferenceKey {
        static var defaultValue: CGRect { .zero }
        static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let currentSide = min(geometry.size.width, max(geometry.size.height - 60, 0))
            let rawSide: CGFloat = {
                if editingItemId != nil, let s = storedCardSide, s >= minValidCardSide { return s }
                return currentSide
            }()
            let cardSide = max(rawSide, minValidCardSide)
            VStack(spacing: editingItemId == nil ? 20 : 0) {
                PageView(selection: $selection) {
                    ForEach(0..<4, id: \.self) { index in
                        let group = index + 1
                        cardContent(for: group, cardSide: cardSide)
                    }
                }
                .pageViewStyle(.cardDeck)
                .frame(width: cardSide, height: cardSide)
                .background(GeometryReader { g in
                    Color.clear.preference(key: CardFramePreferenceKey.self, value: g.frame(in: .global))
                })
                if editingItemId == nil {
                    PageIndicator(selection: $selection, total: 4)
                        .pageIndicatorColor(.gray.opacity(0.5))
                        .pageIndicatorCurrentColor(.white)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .preference(key: CardSideKey.self, value: editingItemId == nil ? currentSide : 0)
            .onPreferenceChange(CardSideKey.self) { newSide in
                if newSide >= minValidCardSide { storedCardSide = newSide }
            }
            .onAppear {
                if storedCardSide == nil, currentSide >= minValidCardSide { storedCardSide = currentSide }
            }
            // 退出编辑时不清空 storedCardSide，保持下次进入编辑时卡片尺寸与首次一致
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selection) { _, _ in
            HapticFeedbackHelper.shared.selection()
            editingItemId = nil
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscription)
                .minNativeSheet(detents: [.large])
        }
    }

    private func isCardUnlocked(group: Int) -> Bool {
        let hasItems = items.contains { $0.group == group }
        return subscription.canUseCard(group: group, hasExistingItems: hasItems)
    }
    
    /// 四张卡片由浅到深的灰色，在黑色背景上易区分且保持统一
    private func cardBackgroundColor(for group: Int) -> Color {
        switch group {
        case 1: return Color(red: 0.155, green: 0.155, blue: 0.165)  // 最浅
        case 2: return Color(red: 0.130, green: 0.130, blue: 0.138)
        case 3: return Color(red: 0.110, green: 0.110, blue: 0.118)  // 原色
        case 4: return Color(red: 0.088, green: 0.088, blue: 0.095)   // 最深
        default: return Color(red: 0.110, green: 0.110, blue: 0.118)
        }
    }
    
    @ViewBuilder
    private func cardContent(for group: Int, cardSide: CGFloat) -> some View {
        let groupData = groupedItems.first(where: { $0.group == group })
        let groupItems = groupData?.items ?? []
        
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(cardBackgroundColor(for: group))
                .shadow(radius: 5)
            
            VStack(spacing: 0) {
                if groupItems.isEmpty {
                    emptyCardView(for: group)
                } else {
                    filledCardView(
                        groupItems: groupItems,
                        group: group,
                        editingItemId: $editingItemId,
                        focusedItemId: $focusedItemId,
                        cardFontSize: cardFontSize,
                        cardRowHeight: cardRowHeight,
                        cardHorizontalPadding: cardHorizontalPadding,
                        cardRowSpacing: cardRowSpacing,
                        cardVerticalInset: cardVerticalInset
                    )
                }
            }
        }
        .frame(width: cardSide, height: cardSide)
    }


    /// 开通用 plus.circle；未开通仅皇冠，外框与圆圈同尺寸
    private func cardActionSymbol(unlocked: Bool, size: CGFloat) -> some View {
        Image(systemName: unlocked ? "plus.circle" : "crown")
            .font(.system(size: size))
            .frame(width: size, height: size)
    }

    // 分解出空卡片视图
    private func emptyCardView(for group: Int) -> some View {
        let unlocked = isCardUnlocked(group: group)
        return VStack {
            Spacer()
            cardActionSymbol(unlocked: unlocked, size: 50)
                .foregroundColor(.gray)
                .opacity(0.3)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if unlocked {
                onAddItem(group)
            } else {
                HapticFeedbackHelper.shared.light()
                showPaywall = true
            }
        }
    }

    // 分解出填充卡片视图
    private func filledCardView(
        groupItems: [Item],
        group: Int,
        editingItemId: Binding<UUID?>,
        focusedItemId: Binding<UUID?>,
        cardFontSize: CGFloat,
        cardRowHeight: CGFloat,
        cardHorizontalPadding: CGFloat,
        cardRowSpacing: CGFloat,
        cardVerticalInset: CGFloat
    ) -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(groupItems) { item in
                    ItemRowView(
                        item: item,
                        editingItemId: editingItemId,
                        focusedItemId: focusedItemId,
                        cardFontSize: cardFontSize,
                        cardRowHeight: cardRowHeight,
                        onSave: { updatedName in
                            item.name = updatedName
                            do {
                                try modelContext.save()
                                saveDataToSharedContainer()
                            } catch {
                                print("保存名称失败: \(error)")
                            }
                        },
                        onDelete: {
                            HapticFeedbackHelper.shared.medium()
                            modelContext.delete(item)
                            do {
                                try modelContext.save()
                                let remainingItems = items.filter { $0.group == group }.sorted { $0.order < $1.order }
                                for (index, it) in remainingItems.enumerated() {
                                    it.order = index
                                }
                                try modelContext.save()
                                saveDataToSharedContainer()
                                // 删除后清空编辑状态，否则 editingItemId 仍为已删项的 id，无法点击同卡片其他行进入编辑
                                editingItemId.wrappedValue = nil
                            } catch {
                                print("删除失败: \(error)")
                            }
                        },
                        onStartReorder: {
                            withAnimation { reorderGroup = group }
                        }
                    )
                    .id(item.id)
                    .listRowInsets(EdgeInsets(
                        top: cardRowSpacing / 2,
                        leading: cardHorizontalPadding,
                        bottom: cardRowSpacing / 2,
                        trailing: cardHorizontalPadding
                    ))
                }
                .onMove { from, to in
                    moveItems(from: from, to: to, inGroup: group)
                }
                
                // 添加更多应用按钮
                if groupItems.count < 4 {
                    addMoreButtonView(for: group)
                        .listRowInsets(EdgeInsets(
                            top: cardRowSpacing / 2,
                            leading: cardHorizontalPadding,
                            bottom: cardRowSpacing / 2,
                            trailing: cardHorizontalPadding
                        ))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .contentMargins(.top, cardVerticalInset, for: .scrollContent)
            .contentMargins(.bottom, cardVerticalInset, for: .scrollContent)
            .environment(\.editMode, .constant(reorderGroup == group ? .active : .inactive))
            .onChange(of: focusedItemId.wrappedValue) { _, newId in
                guard let id = newId, groupItems.contains(where: { $0.id == id }) else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
    }

    // 单行视图：轻点进入编辑，右侧出现删除按钮；长按排序；提交或失焦自动保存（无左滑，避免与切换卡片冲突）
    private struct ItemRowView: View {
        let item: Item
        @Binding var editingItemId: UUID?
        @Binding var focusedItemId: UUID?
        let cardFontSize: CGFloat
        let cardRowHeight: CGFloat
        let onSave: (String) -> Void
        let onDelete: () -> Void
        let onStartReorder: () -> Void
        @State private var editedName: String = ""
        @FocusState private var isFocused: Bool

        private var isEditing: Bool { editingItemId == item.id }

        var body: some View {
            HStack(spacing: 12) {
                if isEditing {
                    TextField("名称", text: $editedName)
                        .font(.system(size: cardFontSize))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit { commitSave() }
                } else {
                    Text(item.name)
                        .font(.system(size: cardFontSize))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if editingItemId == nil {
                                editedName = item.name
                                editingItemId = item.id
                                isFocused = true
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.35) {
                            onStartReorder()
                        }
                }
                if isEditing {
                    Button {
                        HapticFeedbackHelper.shared.medium()
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.28))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("删除")
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(minHeight: cardRowHeight, alignment: .center)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .onChange(of: isFocused) { oldValue, newValue in
                if newValue == true {
                    focusedItemId = item.id
                }
                if oldValue == true && newValue == false {
                    if isEditing { commitSave() }
                    editingItemId = nil
                }
            }
            .onChange(of: editingItemId) { _, newId in
                if newId != item.id { isFocused = false }
            }
        }

        private func commitSave() {
            let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { onSave(trimmed) }
            editingItemId = nil
        }
    }

    // 分解出添加按钮视图（与空卡片 plus.circle 同气质：低对比、无系统蓝）
    private func addMoreButtonView(for group: Int) -> some View {
        let unlocked = isCardUnlocked(group: group)
        return Button(action: {
            if unlocked {
                onAddItem(group)
            } else {
                HapticFeedbackHelper.shared.light()
                showPaywall = true
            }
        }) {
            HStack(spacing: 10) {
                cardActionSymbol(unlocked: unlocked, size: 22)
                Text(unlocked ? "添加应用" : "Pro 解锁")
                    .font(.system(size: 20, weight: .regular))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white.opacity(0.28))
            .frame(minHeight: cardRowHeight, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .accessibilityLabel(unlocked ? "添加更多应用" : "开通 Pro 解锁卡片")
    }
    
    
    
    // 整理后的组数据，确保有4组
    private var groupedItems: [(group: Int, items: [Item])] {
        let result = (1...4).map { group -> (group: Int, items: [Item]) in
            let groupItems = items.filter { $0.group == group }.sorted { $0.order < $1.order }
            return (group: group, items: groupItems)
        }
        return result
    }
    
    // 删除指定组中的项目
    private func deleteItems(at offsets: IndexSet, inGroup group: Int) {
        let groupItems = items.filter { $0.group == group }.sorted { $0.order < $1.order }
        
        for index in offsets {
            if index < groupItems.count {
                modelContext.delete(groupItems[index])
            }
        }
        
        do {
            try modelContext.save()
            
            // 更新组内其余项目的顺序
            let remainingItems = items.filter { $0.group == group }.sorted { $0.order < $1.order }
            for (index, item) in remainingItems.enumerated() {
                item.order = index
            }
            
            try modelContext.save()
            saveDataToSharedContainer()
        } catch {
            print("删除失败: \(error)")
        }
    }
    
    // 移动项目顺序
    private func moveItems(from source: IndexSet, to destination: Int, inGroup group: Int) {
        var groupItems = items.filter { $0.group == group }.sorted { $0.order < $1.order }
        groupItems.move(fromOffsets: source, toOffset: destination)
        
        // 更新顺序
        for (index, item) in groupItems.enumerated() {
            item.order = index
        }
        
        do {
            try modelContext.save()
            saveDataToSharedContainer()
        } catch {
            print("移动失败: \(error)")
        }
    }
    
    // 保存数据到共享容器以更新Widget（从 modelContext 拉取最新数据，避免 @Query 未刷新导致小组件慢一步）
    private func saveDataToSharedContainer() {
        let encoder = JSONEncoder()
        do {
            let descriptor = FetchDescriptor<Item>(sortBy: [SortDescriptor(\.group), SortDescriptor(\.order)])
            let currentItems = try modelContext.fetch(descriptor)
            let widgetItems = currentItems.map { WidgetItem.fromItem($0) }
            let data = try encoder.encode(widgetItems)
            AppGroupStore.set(data, forKey: "widgetItems")
            AppGroupStore.reloadWidgetsDebounced()
        } catch {
            print("数据保存失败: \(error)")
        }
    }
}

#Preview {
    @Previewable @State var selection = 0
    @Previewable @State var editingItemId: UUID? = nil
    let items: [Item] = [
        Item(name: "微信", url: "app1://", nameAdded: Date(), group: 1, order: 0),
        Item(name: "网易云", url: "app2://", nameAdded: Date(), group: 1, order: 2),
        Item(name: "高德地图", url: "app3://", nameAdded: Date(), group: 1, order: 1),
        Item(name: "微博", url: "app3://", nameAdded: Date(), group: 1, order: 3),
        Item(name: "通讯录", url: "app3://", nameAdded: Date(), group: 1, order: 4),
        Item(name: "汽水音乐", url: "app3://", nameAdded: Date(), group: 2, order: 1)
    ]
    return CardDeckView(
        selection: $selection,
        items: items,
        editingItemId: $editingItemId,
        onAddItem: { _ in }
    )
    .environmentObject(SubscriptionManager.shared)
    .modelContainer(for: Item.self, inMemory: true)
    .preferredColorScheme(.dark)
}
