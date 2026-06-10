//
//  MaterialSubcategory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public enum MaterialSubcategory: String, CaseIterable, Sendable, Codable {
    case all
    case monsters
    case herbs
    case fish
    case ores

    public var displayTitle: String {
        switch self {
        case .all:
            return "all"
        case .monsters:
            return "monsters"
        case .herbs:
            return "herbs"
        case .fish:
            return "fish"
        case .ores:
            return "ores"
        }
    }
}
