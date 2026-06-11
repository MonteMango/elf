//
//  DefaultBuffEffectsCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultBuffEffectsCalculator: BuffEffectsCalculator {

    private let buffsRepository: any BuffsRepository

    public init() {
        @Dependency(\.buffsRepository) var buffsRepository
        self.buffsRepository = buffsRepository
    }

    public func apply(buffs: [AppliedBuff], to base: HeroAttributes) -> HeroAttributes {
        guard !buffs.isEmpty else { return base }

        var flatSum = HeroAttributes.zero
        var percentSum: Double = 0
        var percentByAttribute = AttributePercentSum()

        for applied in buffs {
            accumulate(buffId: applied.buffId, stacks: applied.stacks,
                       flatSum: &flatSum, percentSum: &percentSum,
                       percentByAttribute: &percentByAttribute)
        }

        let afterFlat = base + flatSum
        return applyPercent(percentSum, perAttribute: percentByAttribute, to: afterFlat)
    }

    private func accumulate(
        buffId: BuffID,
        stacks: Int,
        flatSum: inout HeroAttributes,
        percentSum: inout Double,
        percentByAttribute: inout AttributePercentSum
    ) {
        guard let buff = buffsRepository.getById(id: buffId) else { return }
        let stacks = max(1, stacks)
        for effect in buff.effects {
            switch effect {
            case .combatAttributesFlat(let delta):
                // Loop add preserves `Attribute`'s overflow-clamp semantics
                // (each `+=` goes through `Int + Int` → `Int16(clamping:)`).
                for _ in 0..<stacks {
                    flatSum.strength += delta.strength
                    flatSum.agility += delta.agility
                    flatSum.power += delta.power
                    flatSum.instinct += delta.instinct
                    flatSum.endurance += delta.endurance
                }
            case .vitalsFlat(let delta):
                for _ in 0..<stacks {
                    flatSum.hitPoints += delta.hitPoints
                    flatSum.manaPoints += delta.manaPoints
                }
            case .combatAttributesPercent(let value):
                percentSum += value * Double(stacks)
            case .combatAttributesPercentDelta(let delta):
                let multiplier = Double(stacks)
                if let value = delta.strength { percentByAttribute.strength += value * multiplier }
                if let value = delta.agility { percentByAttribute.agility += value * multiplier }
                if let value = delta.power { percentByAttribute.power += value * multiplier }
                if let value = delta.instinct { percentByAttribute.instinct += value * multiplier }
                if let value = delta.endurance { percentByAttribute.endurance += value * multiplier }
            }
        }
    }

    /// Apply the combined percent multiplier to combat attributes only.
    /// HP/MP intentionally left untouched in iteration 1 — see protocol doc.
    private func applyPercent(
        _ globalPercent: Double,
        perAttribute: AttributePercentSum,
        to attributes: HeroAttributes
    ) -> HeroAttributes {
        guard globalPercent != 0 || perAttribute.hasAny else { return attributes }

        func scale(_ attr: Attribute, perAttrPercent: Double) -> Attribute {
            let multiplier = max(0, 1.0 + globalPercent + perAttrPercent)
            let scaled = Double(attr.value) * multiplier
            return Attribute(Int16(max(0, Int(scaled.rounded(.down)))))
        }

        return HeroAttributes(
            hitPoints: attributes.hitPoints,
            manaPoints: attributes.manaPoints,
            agility: scale(attributes.agility, perAttrPercent: perAttribute.agility),
            strength: scale(attributes.strength, perAttrPercent: perAttribute.strength),
            power: scale(attributes.power, perAttrPercent: perAttribute.power),
            instinct: scale(attributes.instinct, perAttrPercent: perAttribute.instinct),
            endurance: scale(attributes.endurance, perAttrPercent: perAttribute.endurance)
        )
    }

    private struct AttributePercentSum {
        var strength: Double = 0
        var agility: Double = 0
        var power: Double = 0
        var instinct: Double = 0
        var endurance: Double = 0

        var hasAny: Bool {
            strength != 0 || agility != 0 || power != 0 || instinct != 0 || endurance != 0
        }
    }
}
