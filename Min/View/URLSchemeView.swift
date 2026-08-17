//
//  URL SchemeView.swift
//  Min
//
//  Created by dh on 2025/2/23.
//

import SwiftUI
import SwiftData


struct URLSchemeView: View {
    let appName: String
    @Binding var scheme: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("为 \(appName) 输入URL Scheme")
                    .font(.headline)
        
                //   textfield
                ZStack {
                    HStack {
                        RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))  // 圆角矩形输入框
                            .foregroundStyle(Color.gray.opacity(0.2))
                            .frame(height: 50)
                    }
                    
                    TextField("例如：weixin://", text: $scheme)
                        .frame(height: 50)
                        .padding(.leading,20)
                }
                
                Button(action: {
                    onConfirm()
                }, label: {
                    
                    ZStack {
                        GeometryReader { geometry in
                            RoundedRectangle(cornerSize: CGSize(width: 15, height: 15))
                                .foregroundStyle(Color.gray.opacity(0.2))
                                .frame(width: geometry.size.width * 0.3, height: 50)
                                .position(x: geometry.size.width / 2, y: 25)
                        }
                        .frame(height: 50)
                            
                            Text("确认添加")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                    }
                })
                .disabled(scheme.isEmpty)

            }
            .padding()
            .toolbar(content: {
                Button(action: {
                    scheme = ""
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .fontWeight(.bold)
                        .foregroundStyle(.gray)
                        .padding(10)
                })
            })
            
        }
        .preferredColorScheme(.dark)
        .presentationBackground(.black)
    }
}

    #Preview {
        URLSchemeView(appName: "微信", scheme: .constant(""), onConfirm: { print("请确认添加微信") })
    }
