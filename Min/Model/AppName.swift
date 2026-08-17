//
//  AppName.swift
//  Min
//
//  Created by KangXiang on 2024/12/30.
//

import Foundation

struct AppName: Codable, Identifiable {
    var id = UUID()
    let name: String
    let urlScheme: String
}
