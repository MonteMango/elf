//
//  BuffEffect.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// A single effect produced by a `Buff`. A buff may carry multiple effects.
///
/// Three case shapes, each carrying only the fields it can legally affect —
/// invalid combinations (e.g. "all-attributes percent that secretly bumps HP")
/// are unrepresentable.
///
/// Percent convention: `-0.30` means "−30%". Multiple percent effects on the
/// same combatant sum additively before being applied as a single multiplier
/// `(1 + sumOfPercents)`.
public enum BuffEffect: Sendable, Hashable {
    /// Multiplicative modifier applied to the five combat attributes only
    /// (strength, agility, power, instinct, endurance). HP/MP are untouched
    /// by percent buffs in iteration 1 — use `vitalsFlat` for HP/MP changes.
    case combatAttributesPercent(Double)

    /// Per-attribute percent modifier. `nil` fields are left untouched,
    /// allowing debuffs like Exhausted to target only Strength + Endurance
    /// without touching Agility/Power/Instinct.
    case combatAttributesPercentDelta(CombatAttributesPercentDelta)

    /// Flat additive bonus to the five combat attributes. Type prevents
    /// authoring "I'm a combat buff that also adds 50 HP" by accident.
    case combatAttributesFlat(CombatAttributesDelta)

    /// Flat additive bonus to vitals (HP and MP). Separate from combat
    /// attributes — a single buff effect targets one or the other, not both.
    case vitalsFlat(VitalsDelta)
}

// MARK: - Codable

extension BuffEffect: Codable {

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum EffectType: String, Codable {
        case combatAttributesPercent
        case combatAttributesPercentDelta
        case combatAttributesFlat
        case vitalsFlat
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EffectType.self, forKey: .type)
        switch type {
        case .combatAttributesPercent:
            let value = try container.decode(Double.self, forKey: .value)
            self = .combatAttributesPercent(value)
        case .combatAttributesPercentDelta:
            let value = try container.decode(CombatAttributesPercentDelta.self, forKey: .value)
            self = .combatAttributesPercentDelta(value)
        case .combatAttributesFlat:
            let value = try container.decode(CombatAttributesDelta.self, forKey: .value)
            self = .combatAttributesFlat(value)
        case .vitalsFlat:
            let value = try container.decode(VitalsDelta.self, forKey: .value)
            self = .vitalsFlat(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .combatAttributesPercent(let value):
            try container.encode(EffectType.combatAttributesPercent, forKey: .type)
            try container.encode(value, forKey: .value)
        case .combatAttributesPercentDelta(let delta):
            try container.encode(EffectType.combatAttributesPercentDelta, forKey: .type)
            try container.encode(delta, forKey: .value)
        case .combatAttributesFlat(let delta):
            try container.encode(EffectType.combatAttributesFlat, forKey: .type)
            try container.encode(delta, forKey: .value)
        case .vitalsFlat(let delta):
            try container.encode(EffectType.vitalsFlat, forKey: .type)
            try container.encode(delta, forKey: .value)
        }
    }
}
