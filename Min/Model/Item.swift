//
//  Item.swift
//  Min
//
//  Created by KangXiang on 2024/12/30.
//

import Foundation
import SwiftData

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var name: String
    var url: String
    var nameAdded: Date
    var group: Int
    var order: Int   // 新增属性
    
    init(id: UUID = UUID(), name: String, url: String, nameAdded: Date, group: Int, order: Int) {
        self.id = id
        self.name = name
        self.url = url
        self.nameAdded = nameAdded
        self.group = group
        self.order = order
    }
}
    
    //
    // 扩展Item以支持Codable，但不在主类定义中混合这些代码
    extension Item: Codable {
        enum CodingKeys: String, CodingKey {
            case id, name, url, nameAdded, group, order
        }
        
        convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
            self.init(
                id: id,
                name: try container.decode(String.self, forKey: .name),
                url: try container.decode(String.self, forKey: .url),
                nameAdded: try container.decode(Date.self, forKey: .nameAdded),
                group: try container.decode(Int.self, forKey: .group),
                order: try container.decode(Int.self, forKey: .order)
            )
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(url, forKey: .url)
            try container.encode(nameAdded, forKey: .nameAdded)
            try container.encode(group, forKey: .group)
            try container.encode(order, forKey: .order)
        }
}
