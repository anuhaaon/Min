//
//  TextFieldView.swift
//  Min
//
//  Created by KangXiang on 2024/12/30.
//


import SwiftUI

struct TextFieldView: View {
    @ObservedObject var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack{
            HStack {
                RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))  // 圆角矩形输入框
                    .foregroundStyle(Color.gray.opacity(0.2))
                    .frame(height: 50)
                    .padding(.trailing, isFocused ? 60 : 10)
                    .padding(.leading, 10)
                
                Spacer()
            }
            
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")    // 放大镜
                        .foregroundStyle(Color.gray)
                        .offset(CGSize(width: 0, height: 0))
                        .padding(10)
                    
                    TextField("搜索应用名称", text: $viewModel.searchTerm) //文本输入框
                        .focused($isFocused)
                        .frame(height: 50)
                        .padding(.leading, -10)
                        .onSubmit {
                            // 可选逻辑，例如打印搜索结果或触发其他行为
                            print(viewModel.filteredApps.map { $0.name })
                        }
                }
                .padding()
                
                Button(action: {           //取消按钮
                    isFocused = false
                }) {
                    Text("取消")
                        .frame(width: 50, height: 50)
                        .opacity(isFocused ? 1 : 0)
                        .offset(x: isFocused ? -10 : 30)
                        .foregroundStyle(Color.accentColor)
                        .animation(.easeInOut, value: isFocused)
                }
            }
        }
        .animation(.easeInOut, value: isFocused) // 让整个视图随状态变化平滑过渡
        .preferredColorScheme(.dark)
    }
}

#Preview {
    TextFieldView(viewModel: SearchViewModel())
}
