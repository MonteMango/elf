//
//  RandomAttributeKind.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

/// The five combat-stat attributes that can be granted as a random per-level
/// bonus point. Excludes HP and Mana — those don't roll from
/// `AttributeRandomizer.nextAttribute()`.
public enum RandomAttributeKind: Sendable, CaseIterable, Hashable {
    case agility
    case strength
    case power
    case instinct
    case endurance

    /// Writable key path to the matching `HeroAttributes` stat. Keeps the
    /// kind → property mapping in one place so callers grant a point with
    /// `attributes[keyPath: kind.statKeyPath] += 1` instead of a switch that
    /// has to stay in sync with this enum.
    public var statKeyPath: WritableKeyPath<HeroAttributes, Attribute> {
        switch self {
        case .agility:   \.agility
        case .strength:  \.strength
        case .power:     \.power
        case .instinct:  \.instinct
        case .endurance: \.endurance
        }
    }
}
