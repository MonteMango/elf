//
//  SideMenuType.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation

/// Types of side menu buttons
public enum SideMenuType: String, CaseIterable, Sendable {
    case items = "Items"
    case skills = "Skills"
    case war = "War"
    case house = "House"

    /// SF Symbol icon name for the menu item
    public var iconName: String {
        switch self {
        case .items: return "bag.fill"
        case .skills: return "sparkles"
        case .war: return "shield.lefthalf.filled"
        case .house: return "house.fill"
        }
    }
}
