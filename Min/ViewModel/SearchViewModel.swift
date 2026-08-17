//
//  SearchViewModel.swift
//  Min
//
//  Created by KangXiang on 2024/12/30.
//

import Foundation
import Combine


class SearchViewModel: ObservableObject {
    @Published var searchTerm: String = ""
    @Published var filteredApps: [AppName] = []
    
    private var allApps: [AppName] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 加载 JSON 数据
        if let url = Bundle.main.url(forResource: "URLSchemeData", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: String]] {
            self.allApps = json.compactMap { dict in
                guard let name = dict["name"], let urlScheme = dict["urlScheme"] else { return nil }
                return AppName(name: name, urlScheme: urlScheme)
            }
        }
        
        // 绑定搜索关键词到过滤操作
        $searchTerm
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { [weak self] term in
                self?.filterApps(by: term) ?? []
            }
            .assign(to: &$filteredApps)
    }
    
    private func filterApps(by term: String) -> [AppName] {
        guard !term.isEmpty else { return allApps }
        return allApps.filter { $0.name.contains(term) }
    }
}

