//
//  ElfAttributeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 01.11.24.
//

import Dependencies
import Foundation

public final class ElfAttributeService: AttributeService {

    private let itemsRepository: any ItemsRepository
    private let randomizer: any AttributeRandomizer

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.attributeRandomizer) var randomizer
        self.itemsRepository = itemsRepository
        self.randomizer = randomizer
    }

    public func getAllFightStyleAttributes(for fightStyle: FightStyle, at level: Int16) -> HeroAttributes {
        // Base HP 80 + 5 per level applies to every fight style (so a lvl-12
        // hero starts a battle with 140 HP). Per-style differentiation is
        // expressed via offensive/defensive stats, not HP scaling.
        let hitPoints = Attribute(80 + 5 * level)

        switch fightStyle {
        case .crit:
            // 6-point budget per level: str 1 + pow 4 + int 1 + end 0 + agi 0.
            // Canonical original allocation. Per design constraint, crit has
            // NO agility (agility is dodge's identity) and NO endurance.
            // Intuition stays at 1×level — partially suppresses opponent
            // dodge/crit chance and drives crit's own damage reduction via
            // `the sqrt reduction curve`.
            return HeroAttributes(
                hitPoints: hitPoints,
                manaPoints: 20,
                agility: 0,
                strength: Attribute(1 * level),
                power: Attribute(4 * level),
                instinct: Attribute(1 * level),
                endurance: 0
            )

        case .def:
            // 6-point budget per level: str 1 + int 2 + end 3 + pow 0 + agi 0.
            // Endurance load-bears blocks economy (via blocksPerEndurancePoint).
            // Intuition load-bears damage reduction (via
            // the sqrt reduction curve) and suppresses opponent
            // dodge/crit. Zero power, zero agility — def fights via attrition.
            return HeroAttributes(
                hitPoints: hitPoints,
                manaPoints: 20,
                agility: 0,
                strength: Attribute(1 * level),
                power: 0,
                instinct: Attribute(2 * level),
                endurance: Attribute(3 * level)
            )

        case .dodge:
            // 6-point budget per level: str 1 + agi 4 + int 1 + pow 0 + end 0.
            // Intuition kept at 1×level — partially suppresses crit's chance
            // when dodge faces an attacker with power (today only relevant in
            // dodge-vs-crit; in dodge-vs-def the def has 0 power so dodge's
            // intuition does nothing). Agility load-bears the dodge identity.
            return HeroAttributes(
                hitPoints: hitPoints,
                manaPoints: 20,
                agility: Attribute(4 * level),
                strength: Attribute(1 * level),
                power: 0,
                instinct: Attribute(1 * level),
                endurance: 0
            )
        }
    }

    public func getRandomLevelAttributes() -> HeroAttributes {
        var attributes = HeroAttributes()
        for _ in 0..<4 {
            attributes[keyPath: randomizer.nextAttribute().statKeyPath] += 1
        }
        return attributes
    }

    public func getAllRandomLevelAttributes(for level: Int16) -> HeroAttributes {
        // Sequential execution - getRandomLevelAttributes is a lightweight operation
        var totalAttributes = HeroAttributes()
        for _ in 1...level {
            let attributes = getRandomLevelAttributes()
            totalAttributes.hitPoints += attributes.hitPoints
            totalAttributes.manaPoints += attributes.manaPoints
            totalAttributes.agility += attributes.agility
            totalAttributes.strength += attributes.strength
            totalAttributes.power += attributes.power
            totalAttributes.instinct += attributes.instinct
            totalAttributes.endurance += attributes.endurance
        }
        return totalAttributes
    }

    public func getAllItemsAttributes(for itemIds: [ItemID]) -> HeroAttributes {
        var aggregatedAttributes = HeroAttributes()
        for itemId in itemIds {
            if let item = itemsRepository.getHeroItem(itemId) {
                aggregatedAttributes = aggregateItemAttributes(item: item, existingAttributes: aggregatedAttributes)
            }
        }
        return aggregatedAttributes
    }

    private func aggregateItemAttributes(item: Item, existingAttributes: HeroAttributes) -> HeroAttributes {
        var updatedAttributes = existingAttributes
        if let strength = item.strength {
            updatedAttributes.strength += strength
        }
        if let agility = item.agility {
            updatedAttributes.agility += agility
        }
        if let power = item.power {
            updatedAttributes.power += power
        }
        if let instinct = item.instinct {
            updatedAttributes.instinct += instinct
        }
        if let endurance = item.endurance {
            updatedAttributes.endurance += endurance
        }
        if let hitPoints = item.hitPoints {
            updatedAttributes.hitPoints += hitPoints
        }
        if let manaPoints = item.manaPoints {
            updatedAttributes.manaPoints += manaPoints
        }
        return updatedAttributes
    }
}
