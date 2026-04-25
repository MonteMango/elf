//
//  HeroAttributes.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 31.10.24.
//

/// Hero attributes using type-safe Attribute wrapper.
///
/// All values are guaranteed to be non-negative through the Attribute type.
public struct HeroAttributes: Sendable, Hashable, Equatable, Codable {

    // MARK: - Properties

    public var hitPoints: Attribute
    public var manaPoints: Attribute
    public var agility: Attribute
    public var strength: Attribute
    public var power: Attribute
    public var instinct: Attribute

    // MARK: - Initialization

    /// Creates attributes with default zero values
    public init() {
        self.hitPoints = .zero
        self.manaPoints = .zero
        self.agility = .zero
        self.strength = .zero
        self.power = .zero
        self.instinct = .zero
    }

    /// Creates attributes with Attribute values.
    /// Integer literals are automatically converted via ExpressibleByIntegerLiteral.
    public init(
        hitPoints: Attribute,
        manaPoints: Attribute,
        agility: Attribute,
        strength: Attribute,
        power: Attribute,
        instinct: Attribute
    ) {
        self.hitPoints = hitPoints
        self.manaPoints = manaPoints
        self.agility = agility
        self.strength = strength
        self.power = power
        self.instinct = instinct
    }

    // MARK: - Arithmetic

}

// MARK: - AdditiveArithmetic

extension HeroAttributes: AdditiveArithmetic {

    public static var zero: HeroAttributes { HeroAttributes() }

    public static func + (lhs: HeroAttributes, rhs: HeroAttributes) -> HeroAttributes {
        HeroAttributes(
            hitPoints: lhs.hitPoints + rhs.hitPoints,
            manaPoints: lhs.manaPoints + rhs.manaPoints,
            agility: lhs.agility + rhs.agility,
            strength: lhs.strength + rhs.strength,
            power: lhs.power + rhs.power,
            instinct: lhs.instinct + rhs.instinct
        )
    }

    public static func - (lhs: HeroAttributes, rhs: HeroAttributes) -> HeroAttributes {
        HeroAttributes(
            hitPoints: lhs.hitPoints - rhs.hitPoints,
            manaPoints: lhs.manaPoints - rhs.manaPoints,
            agility: lhs.agility - rhs.agility,
            strength: lhs.strength - rhs.strength,
            power: lhs.power - rhs.power,
            instinct: lhs.instinct - rhs.instinct
        )
    }
}
