////
////  Untitled.swift
////  Min
////
////  Created by dh on 2025/2/22.
////
//
import Combine
import SwiftUI

class AppStoreSearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var apps: [AppStoreApp] = []
    @Published var isLoading = false // 新增加载状态
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.searchApps(text: text)
            }
            .store(in: &cancellables)
    }
    
    private func searchApps(text: String) {
        guard !text.isEmpty else {
            apps = []
            return
        }
        
        
        isLoading = true // 开始加载
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlStr = "https://itunes.apple.com/search?term=\(encodedText)&country=cn&entity=software"
        
        guard let url = URL(string: urlStr) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            defer { DispatchQueue.main.async { self.isLoading = false } } // 结束加载
            
            if let data = data {
                do {
                    let result = try JSONDecoder().decode(SearchResult.self, from: data)
                    DispatchQueue.main.async {
                        self.apps = result.results
                    }
                } catch {
                    print("解析失败: \(error)")
                }
            }
        }.resume()
    }
}

struct SearchResult: Decodable {
    let results: [AppStoreApp]
}

struct AppStoreApp: Decodable, Identifiable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let artworkUrl60: String
    let trackViewUrl: String
    
    var id: Int { trackId }

    var artworkURL: URL? {
        URL(string: artworkUrl60.replacingOccurrences(of: "60x60", with: "120x120"))
    }
}
