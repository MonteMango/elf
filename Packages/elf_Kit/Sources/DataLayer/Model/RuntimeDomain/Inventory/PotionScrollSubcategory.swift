//
//  PotionScrollSubcategory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public enum PotionScrollSubcategory: String, CaseIterable, Sendable {
    case all
    case potions
    case scrolls

    public var displayTitle: String {
        switch self {
        case .all:
            return "all"
        case .potions:
            return "potions"
        case .scrolls:
            return "scrolls"
        }
    }
}
