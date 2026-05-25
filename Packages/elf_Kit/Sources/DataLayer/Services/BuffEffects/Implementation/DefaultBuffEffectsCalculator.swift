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

        for applied in buffs {
            accumulate(buffId: applied.buffId, stacks: applied.stacks,
                       flatSum: &flatSum, percentSum: &percentSum)
        }

        let afterFlat = base + flatSum
        return applyPercent(percentSum, to: afterFlat)
    }

    private func accumulate(
        buffId: UUID,
        stacks: Int,
        flatSum: inout HeroAttributes,
        percentSum: inout Double
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
            }
        }
    }

    /// Apply the combined percent multiplier to combat attributes only.
    /// HP/MP intentionally left untouched in iteration 1 — see protocol doc.
    private func applyPercent(_ percent: Double, to attributes: HeroAttributes) -> HeroAttributes {
        guard percent != 0 else { return attributes }
        let multiplier = max(0, 1.0 + percent)

        func scale(_ attr: Attribute) -> Attribute {
            let scaled = Double(attr.value) * multiplier
            return Attribute(Int16(max(0, Int(scaled.rounded(.down)))))
        }

        return HeroAttributes(
            hitPoints: attributes.hitPoints,
            manaPoints: attributes.manaPoints,
            agility: scale(attributes.agility),
            strength: scale(attributes.strength),
            power: scale(attributes.power),
            instinct: scale(attributes.instinct),
            endurance: scale(attributes.endurance)
        )
    }
}
