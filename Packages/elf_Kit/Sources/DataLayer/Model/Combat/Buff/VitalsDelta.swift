//
//  VitalsDelta.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

/// Additive delta over vital pools (HP and MP). Used by `BuffEffect.vitalsFlat`
/// to express "this buff modifies max-HP / max-MP" separately from combat
/// attributes.
///
/// Type-driven: complements `CombatAttributesDelta` — together they cover the
/// seven `HeroAttributes` fields, but each carries only the subset a given
/// buff effect is allowed to address. A buff cannot accidentally bundle
/// combat-stat + HP changes under one effect.
public struct VitalsDelta: Sendable, Hashable, Codable {

    // MARK: - Properties

    public var hitPoints: Attribute
    public var manaPoints: Attribute

    // MARK: - Initialization

    public init(
        hitPoints: Attribute = .zero,
        manaPoints: Attribute = .zero
    ) {
        self.hitPoints = hitPoints
        self.manaPoints = manaPoints
    }
}
