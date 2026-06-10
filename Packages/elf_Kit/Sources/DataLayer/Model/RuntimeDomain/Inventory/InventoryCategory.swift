//
//  InventoryCategory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Main categories for inventory filtering
public enum InventoryCategory: String, CaseIterable, Sendable {
    case weapons
    case armor
    case potionsScrolls  // placeholder for future implementation
    case materials

    public var displayTitle: String {
        switch self {
        case .weapons:
            return "weapon"
        case .armor:
            return "armor"
        case .potionsScrolls:
            return "potions &\nscrolls"
        case .materials:
            return "materials"
        }
    }
}
