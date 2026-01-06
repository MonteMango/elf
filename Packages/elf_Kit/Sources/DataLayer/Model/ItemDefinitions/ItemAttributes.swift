//
//  ItemAttributes.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Shared attribute bonuses that items can provide.
///
/// This struct groups all stat bonuses in one place, using the `Attribute`
/// wrapper type to ensure non-negative values.
///
/// ## Usage
/// ```swift
/// let attributes = ItemAttributes(
///     strength: 10,
///     agility: 5,
///     hitPoints: 20
/// )
///
/// let totalStrength = baseAttributes.strength + attributes.strength
/// ```
public struct ItemAttributes: Sendable, Hashable, Equatable, Codable {

    /// Strength bonus
    public let strength: Attribute

    /// Agility bonus
    public let agility: Attribute

    /// Power (magic) bonus
    public let power: Attribute

    /// Instinct bonus
    public let instinct: Attribute

    /// Hit points bonus
    public let hitPoints: Attribute

    /// Mana points bonus
    public let manaPoints: Attribute

    /// Zero attributes (no bonuses)
    public static let zero = ItemAttributes()

    /// Creates item attributes with specified values.
    /// All values default to zero if not provided.
    public init(
        strength: Attribute = .zero,
        agility: Attribute = .zero,
        power: Attribute = .zero,
        instinct: Attribute = .zero,
        hitPoints: Attribute = .zero,
        manaPoints: Attribute = .zero
    ) {
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
        self.hitPoints = hitPoints
        self.manaPoints = manaPoints
    }

    /// Creates item attributes from optional Int16 values (for backward compatibility).
    /// Nil values become zero.
    public static func fromOptionals(
        strength: Int16? = nil,
        agility: Int16? = nil,
        power: Int16? = nil,
        instinct: Int16? = nil,
        hitPoints: Int16? = nil,
        manaPoints: Int16? = nil
    ) -> ItemAttributes {
        ItemAttributes(
            strength: Attribute(strength ?? 0),
            agility: Attribute(agility ?? 0),
            power: Attribute(power ?? 0),
            instinct: Attribute(instinct ?? 0),
            hitPoints: Attribute(hitPoints ?? 0),
            manaPoints: Attribute(manaPoints ?? 0)
        )
    }

    /// Whether this has any non-zero attributes
    public var hasAnyBonus: Bool {
        strength > .zero || agility > .zero || power > .zero ||
        instinct > .zero || hitPoints > .zero || manaPoints > .zero
    }

    /// Combines attributes from two items (addition)
    public static func + (lhs: ItemAttributes, rhs: ItemAttributes) -> ItemAttributes {
        ItemAttributes(
            strength: lhs.strength + rhs.strength,
            agility: lhs.agility + rhs.agility,
            power: lhs.power + rhs.power,
            instinct: lhs.instinct + rhs.instinct,
            hitPoints: lhs.hitPoints + rhs.hitPoints,
            manaPoints: lhs.manaPoints + rhs.manaPoints
        )
    }
}

// MARK: - Conversion from existing Item protocol

extension ItemAttributes {
    /// Creates ItemAttributes from any existing Item protocol implementation.
    /// This is useful for gradual migration from the old Item types.
    public static func from(item: any Item) -> ItemAttributes {
        fromOptionals(
            strength: item.strength,
            agility: item.agility,
            power: item.power,
            instinct: item.instinct,
            hitPoints: item.hitPoints,
            manaPoints: item.manaPoints
        )
    }
}
