//
//  AppSearchView.swift
//  Min
//
//  Created by dh on 2025/2/22.
//

import SwiftUI
import SwiftData
import WidgetKit

struct AppStoreSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var appStoreSearchviewModel = AppStoreSearchViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    
    @State private var selectedApp: AppStoreApp? = nil
    @State private var customURLScheme = ""
    @State private var showURLSchemeInput = false
    @State private var shouldDismissWhenFull = false

    var targetGroup: Int
    private let maxItemsPerCard = 4
    
    init(targetGroup: Int = 1) {
        self.targetGroup = targetGroup
    }

    var body: some View {
        
        NavigationStack {
            VStack {
                TextField("搜索App Store", text: $appStoreSearchviewModel.searchText)
                                   .padding(.horizontal, 15)
                                   .frame(height: 50)
                                   .background(Color.gray.opacity(0.2))
                                   .cornerRadius(15)
                                   .padding(EdgeInsets(top: 30, leading: 10, bottom: 0, trailing: 10))
                
                if appStoreSearchviewModel.isLoading {
                                  Spacer()
                                  ProgressView()
                                      .scaleEffect(1.5)
                                      .padding()
                                  Spacer()
                              } else if appStoreSearchviewModel.apps.isEmpty {
                                  Spacer()
                                  Image(systemName: "magnifyingglass")
                                      .font(.system(size: 44, weight: .medium))
                                      .foregroundStyle(.white.opacity(0.28))
                                  Spacer()
                              } else {
                                  List {
                                      ForEach(appStoreSearchviewModel.apps) { app in
                                          HStack(spacing: 12) {
                                              AsyncImage(url: app.artworkURL) { image in
                                                      image
                                                          .resizable()
                                                          .scaledToFill()
                                                          .frame(width: 35, height: 35)
                                                          .cornerRadius(10)
                                                  } placeholder: {
                                                      Image(systemName: "app.fill")
                                                          .resizable()
                                                          .scaledToFill()
                                                          .frame(width: 35, height: 35)
                                                          .cornerRadius(10)
                                                          .foregroundColor(.gray)
                                              }
                                              Text(app.trackName)
                                                  .lineLimit(1)
                                                  .padding(.leading, 10)
                                          }
                                          .padding(.vertical, 5)
                                          .listRowSeparator(.hidden)
                                          .listRowBackground(Color.black)
                                          .onTapGesture {
                                              guard countItemsInGroup(targetGroup) < maxItemsPerCard else {
                                                  dismiss()
                                                  return
                                              }
                                              selectedApp = app
                                              showURLSchemeInput = true
                                          }
                                      }
                                  }
                                  .scrollIndicators(.hidden)
                                  .overlay(alignment: .top) {
                                      MinEdgeFade(edge: .top, height: 30)
                                  }
                                  .overlay(alignment: .bottom) {
                                      MinEdgeFade(edge: .bottom, height: 30)
                                  }
                                  .ignoresSafeArea(.container, edges: .bottom)
                                  .listStyle(PlainListStyle())
                              }
                          }
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
                        .sheet(isPresented: $showURLSchemeInput, onDismiss: {
                            customURLScheme = ""
                            selectedApp = nil
                            if shouldDismissWhenFull {
                                dismiss()
                            }
                        }) {
                              URLSchemeView(
                                  appName: selectedApp?.trackName ?? "",
                                  scheme: $customURLScheme,
                                  onConfirm: {
                                      addAppStoreApp()
                                      HapticFeedbackHelper.shared.light()
                                      showURLSchemeInput = false
                                  }
                              )
                              .presentationDetents([.medium])
                          }
                      }
                      .presentationBackground(.black)
                      .preferredColorScheme(.dark)
                  }
    
    
    
    
    private func addAppStoreApp() {
        guard let app = selectedApp else { return }
        
        let countInGroup = countItemsInGroup(targetGroup)
        guard countInGroup < maxItemsPerCard else {
            shouldDismissWhenFull = true
            return
        }
        
        let scheme = customURLScheme.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !scheme.isEmpty else { return }

        let newItem = Item(
            name: app.trackName,
            url: scheme,
            nameAdded: Date(),
            group: targetGroup,
            order: countInGroup
        )
        
        modelContext.insert(newItem)
        try? modelContext.save()
        saveDataToSharedContainer()
        
        if countInGroup + 1 >= maxItemsPerCard {
            shouldDismissWhenFull = true
        }
    }
    
    // 计算指定分组中的项目数量
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
         
         // 转换为WidgetItems
         let widgetItems = items.map { WidgetItem.fromItem($0) }
         
         // 保存到共享容器
         let encoder = JSONEncoder()
         do {
             let data = try encoder.encode(widgetItems)
             AppGroupStore.set(data, forKey: "widgetItems")
             AppGroupStore.reloadWidgetsDebounced()
         } catch {
             print("数据保存失败: \(error)")
         }
     }
}

#Preview {
    AppStoreSearchView(targetGroup: 2)
        .modelContainer(for: Item.self, inMemory: true)
}
