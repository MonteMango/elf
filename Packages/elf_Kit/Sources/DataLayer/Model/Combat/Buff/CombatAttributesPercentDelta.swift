//
//  CombatAttributesPercentDelta.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Selective percent modifier over the five combat attributes. Mirrors
/// `CombatAttributesDelta` (flat counterpart) but expresses multiplicative
/// per-attribute adjustments — `nil` means "leave this attribute untouched".
///
/// Used by `BuffEffect.combatAttributesPercentDelta` to encode debuffs like
/// "Exhausted: only Strength and Endurance reduced by 30 %", which the broader
/// `BuffEffect.combatAttributesPercent(Double)` (applies to all five) cannot
/// express. Percent convention matches the rest of the buff system:
/// `-0.30` means "−30 %".
public struct CombatAttributesPercentDelta: Sendable, Hashable, Codable {

    public var strength: Double?
    public var agility: Double?
    public var power: Double?
    public var instinct: Double?
    public var endurance: Double?

    public init(
        strength: Double? = nil,
        agility: Double? = nil,
        power: Double? = nil,
        instinct: Double? = nil,
        endurance: Double? = nil
    ) {
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
        self.endurance = endurance
    }
}
