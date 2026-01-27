//
//  InventorySubcategory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Weapon Subcategories

public enum WeaponSubcategory: String, CaseIterable, Sendable {
    case all
    case oneHand
    case twoHands
    case shields

    public var displayTitle: String {
        switch self {
        case .all:
            return "all"
        case .oneHand:
            return "one hand"
        case .twoHands:
            return "two\nhands"
        case .shields:
            return "shields"
        }
    }
}

// MARK: - Armor Subcategories

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

// MARK: - Potion & Scroll Subcategories

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

// MARK: - Material Subcategories

public enum MaterialSubcategory: String, CaseIterable, Sendable, Codable {
    case all
    case monsters
    case herbs
    case fish
    case stones

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
        case .stones:
            return "stones"
        }
    }
}
