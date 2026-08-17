//
//  SearchView.swift
//  Min
//
//  Created by KangXiang on 2024/12/30.
//

import SwiftUI
import SwiftData
import WidgetKit

struct SearchView: View {
    
    @StateObject var searchViewModel = SearchViewModel()
    @FocusState private var isFocused: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAppStoreSearch = false
    
    // 接收目标分组参数
    let targetGroup: Int
    
    init(targetGroup: Int) {
        self.targetGroup = targetGroup
    }
    
    var body: some View {
        NavigationStack {
            VStack { 
                Spacer()
                TextFieldView(viewModel: searchViewModel)   //  搜索栏
                    .padding(.top, 10)
                
                List(searchViewModel.filteredApps) { app in  // 搜索结果list
                    Button(action: {
                        // 添加到指定分组
                        addNameToGroup(app: app, group: targetGroup)
                        HapticFeedbackHelper.shared.light()
                        dismiss()
                    }, label: {
                        HStack(spacing: 10) {
                            AppStoreIconView(name: app.name)

                            Text(app.name)
                                .foregroundStyle(.white)

                            Spacer(minLength: 8)

                            if SystemAppSymbol.isSystem(app.name) {
                                Text("系统")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.32))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.08))
                                    )
                            }
                        }
                        .padding(.vertical, 3)
                    })
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.black)
                }
                .overlay(alignment: .top) {
                    MinEdgeFade(edge: .top, height: 30)
                }
                .overlay(alignment: .bottom) {
                    MinEdgeFade(edge: .bottom, height: 30)
                }
                .ignoresSafeArea(.container, edges: .bottom)
                .padding(.bottom, 10)
                .listStyle(PlainListStyle())
                .scrollIndicators(.hidden)
                
                Button(action: {          //   "添加更多应用"button
                    guard countItemsInGroup(targetGroup) < 4 else {
                        dismiss()
                        return
                    }
                    HapticFeedbackHelper.shared.light()
                    showAppStoreSearch.toggle()
                }, label: {
                    ZStack{
                        RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                            .foregroundStyle(Color.gray.opacity(0.2))
                            .frame(height: 50)
                            .padding(.horizontal, 20)
                        Text("添加更多应用")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                })
                .sheet(isPresented: $showAppStoreSearch, onDismiss: {
                    if countItemsInGroup(targetGroup) >= 4 {
                        dismiss()
                    }
                }) {
                    AppStoreSearchView(targetGroup: targetGroup)
                }
                
                Spacer()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationTitle("添加应用到小组件 \(targetGroup)")
            .toolbar(content: {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                        .padding(10)
                })
            })
        }
        .presentationBackground(.black)
    }
    
    // 添加应用到指定分组
    private func addNameToGroup(app: AppName, group: Int) {
        // 计算当前分组中的项目数量
        let countInGroup = countItemsInGroup(group)
        guard countInGroup < 4 else { return }  // 每组最多4个
        
        // 创建新项目并设置顺序为当前组内数量
        let newItem = Item(name: app.name, url: app.urlScheme, nameAdded: Date(), group: group, order: countInGroup)
        
        modelContext.insert(newItem)
        do {
            try modelContext.save()
            saveDataToSharedContainer() //更新widget数据
        } catch {
            print("保存失败: \(error)")
        }
    }
    
    // 辅助函数：计算某组的项数
    private func countItemsInGroup(_ group: Int) -> Int {
        let predicate = #Predicate<Item> { $0.group == group }
        let descriptor = FetchDescriptor(predicate: predicate)
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
    
    // 更新Widget数据的方法
    private func saveDataToSharedContainer() {
        // 获取所有Items
        let descriptor = FetchDescriptor<Item>()
        guard let items = try? modelContext.fetch(descriptor) else { return }
        
        // 保存到共享容器（小组件用 [WidgetItem] 解码，须写入该格式）
        let encoder = JSONEncoder()
        do {
            let widgetItems = items.map { WidgetItem.fromItem($0) }
            let data = try encoder.encode(widgetItems)
            AppGroupStore.set(data, forKey: "widgetItems")
            AppGroupStore.reloadWidgetsDebounced()
        } catch {
            print("数据保存失败: \(error)")
        }
    }
}

#Preview {
    SearchView(targetGroup: 2)
        .modelContainer(for: Item.self, inMemory: true)
}
