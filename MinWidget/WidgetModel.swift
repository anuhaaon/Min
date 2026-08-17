//
//  WidgetModel.swift
//  Min
//
//  Created by dh on 2025/3/8.
//

import Foundation
import SwiftUI
import WidgetKit
import SwiftData

struct WidgetItem: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var url: String
    var order: Int
    var group: Int
    
    static func fromItem(_ item: Item) -> WidgetItem {
        return WidgetItem(
            id: item.id,
            name: item.name,
            url: item.url,
            order: item.order,
            group: item.group
        )
    }
}

struct WidgetData: Codable {
    var items: [WidgetItem]
    
    var fontSetting: FontSetting
    var textAlignment: TextAlignmentType
    
    init(items: [WidgetItem] = [], fontSetting: FontSetting = FontSetting(), textAlignment: TextAlignmentType = .leading) {
        self.items = items
        self.fontSetting = fontSetting
        self.textAlignment = textAlignment
    }

    
    static func loadFromSharedContainer() -> WidgetData {
        var items: [WidgetItem] = []
        if let data = AppGroupStore.data(forKey: "widgetItems"),
           let decodedItems = try? JSONDecoder().decode([WidgetItem].self, from: data) {
            items = decodedItems
        }
        
        var fontSetting = FontSetting()
        if let data = AppGroupStore.data(forKey: "fontSetting"),
           let decodedFontSetting = try? JSONDecoder().decode(FontSetting.self, from: data) {
            fontSetting = decodedFontSetting
        }
        
        var textAlignment = TextAlignmentType.leading
        if let data = AppGroupStore.data(forKey: "textAlignment"),
           let decodedAlignment = try? JSONDecoder().decode(TextAlignmentType.self, from: data) {
            textAlignment = decodedAlignment
        }
        
        return WidgetData(items: items, fontSetting: fontSetting, textAlignment: textAlignment)
    }
}