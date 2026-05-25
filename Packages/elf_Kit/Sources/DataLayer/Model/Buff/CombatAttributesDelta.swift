//
//  CombatAttributesDelta.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

/// Additive delta over the five combat attributes (strength, agility, power,
/// instinct, endurance). Used by `BuffEffect.combatAttributesFlat` to express
/// "this buff modifies combat stats by these increments" without leaking HP/MP
/// fields the buff is not meant to touch.
///
/// Type-driven: by *not* including `hitPoints`/`manaPoints`, the type makes
/// invalid combat-flat buffs (e.g. `+50 HP` mistakenly authored as a combat
/// buff) unrepresentable. HP/MP deltas live on `VitalsDelta`.
public struct CombatAttributesDelta: Sendable, Hashable, Codable {

    // MARK: - Properties

    public var strength: Attribute
    public var agility: Attribute
    public var power: Attribute
    public var instinct: Attribute
    public var endurance: Attribute

    // MARK: - Initialization

    public init(
        strength: Attribute = .zero,
        agility: Attribute = .zero,
        power: Attribute = .zero,
        instinct: Attribute = .zero,
        endurance: Attribute = .zero
    ) {
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
        self.endurance = endurance
    }
}
