//
//  GatherableTier.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Tier/rarity level for gatherable items (fish, herbs, minerals).
///
/// Lower rawValue = rarer item. This ordering allows natural sorting
/// where legendary items come first.
///
/// ## XP Values (from game-design.md)
/// - Legendary (tier 1): 20 XP
/// - Rare (tier 2): 12 XP
/// - Uncommon (tier 3): 8 XP
/// - Common (tier 4): 5 XP
public enum GatherableTier: Int, Codable, Sendable, Hashable, CaseIterable, Comparable {
    case legendary = 1
    case rare = 2
    case uncommon = 3
    case common = 4

    /// XP value awarded for gathering an item of this tier
    public var xpValue: Int {
        switch self {
        case .legendary: 20
        case .rare: 12
        case .uncommon: 8
        case .common: 5
        }
    }

    /// Comparable: lower rawValue (rarer) is "less than" higher rawValue (more common)
    public static func < (lhs: GatherableTier, rhs: GatherableTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
