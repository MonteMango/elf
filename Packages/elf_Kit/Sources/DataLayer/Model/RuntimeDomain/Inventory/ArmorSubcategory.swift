//
//  ArmorSubcategory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public enum ArmorSubcategory: String, CaseIterable, Sendable {
    case all
    case armor
    case jewelry

    public var displayTitle: String {
        switch self {
        case .all:
            return "all"
        case .armor:
            return "armor"
        case .jewelry:
            return "jewelry"
        }
    }
}
