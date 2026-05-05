//
//  BattleSetupDisplayModels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Hero Configuration State

@MainActor
@Observable
public final class HeroConfigurationState {
    public var level: Int
    public var fightStyle: FightStyle?
    public var fightStyleAttributes: HeroAttributes?
    public var levelRandomAttributes: HeroAttributes?
    public var itemsAttributes: HeroAttributes?
    public var armorValues: [BodyPart: Int16]
    public var leftHandDamage: (minDmg: Int16, maxDmg: Int16)?
    public var rightHandDamage: (minDmg: Int16, maxDmg: Int16)?
    public var selectedItems: [HeroItemType: UUID?]
    public var twoHandedWeaponId: UUID?

    public var totalAttributes: HeroAttributes? {
        guard let fightStyle = fightStyleAttributes,
              let level = levelRandomAttributes else {
            return nil
        }

        let items = itemsAttributes ?? HeroAttributes()

        return HeroAttributes(
            hitPoints: fightStyle.hitPoints + level.hitPoints + items.hitPoints,
            manaPoints: fightStyle.manaPoints + level.manaPoints + items.manaPoints,
            agility: fightStyle.agility + level.agility + items.agility,
            strength: fightStyle.strength + level.strength + items.strength,
            power: fightStyle.power + level.power + items.power,
            instinct: fightStyle.instinct + level.instinct + items.instinct,
            endurance: fightStyle.endurance + level.endurance + items.endurance
        )
    }

    public init(level: Int = 1) {
        self.level = level
        self.fightStyle = nil
        self.fightStyleAttributes = nil
        self.levelRandomAttributes = nil
        self.itemsAttributes = nil
        self.armorValues = [:]
        self.leftHandDamage = nil
        self.rightHandDamage = nil
        self.selectedItems = [:]
        self.twoHandedWeaponId = nil
    }
}

// MARK: - Item Selector State

public struct ItemSelectorState: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let heroType: HeroType
    public let itemType: HeroItemType
    public let currentItemId: UUID?

    public init(heroType: HeroType, itemType: HeroItemType, currentItemId: UUID?) {
        self.heroType = heroType
        self.itemType = itemType
        self.currentItemId = currentItemId
    }
}
