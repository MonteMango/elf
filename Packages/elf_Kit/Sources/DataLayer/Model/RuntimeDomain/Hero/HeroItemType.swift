//
//  HeroItemType.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 31.10.24.
//

public enum HeroItemType: String, Sendable, Codable {
    case helmet
    case gloves
    case shoes
    case upperBody
    case bottomBody
    case shirt
    case ring
    case necklace
    case earrings
    case weapons
    case shields
}

public extension HeroItemType {
    var isJewelry: Bool {
        switch self {
        case .ring, .necklace, .earrings:
            return true
        case .helmet, .gloves, .shoes, .upperBody, .bottomBody, .shirt, .weapons, .shields:
            return false
        }
    }

    /// Human-readable label for VoiceOver / debug.
    var accessibilityLabel: String {
        switch self {
        case .helmet:     return "Helmet"
        case .gloves:     return "Gloves"
        case .shoes:      return "Shoes"
        case .upperBody:  return "Upper body"
        case .bottomBody: return "Lower body"
        case .shirt:      return "Shirt"
        case .ring:       return "Ring"
        case .necklace:   return "Necklace"
        case .earrings:   return "Earrings"
        case .weapons:    return "Weapon"
        case .shields:    return "Shield"
        }
    }
}
