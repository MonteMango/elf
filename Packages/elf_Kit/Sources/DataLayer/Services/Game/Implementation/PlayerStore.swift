//
//  PlayerStore.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.04.26.
//

import Foundation
import Observation

/// Observable wrapper over player `ElfInfo` fields.
///
/// Provides per-field SwiftUI observation: mutating `currentExp` does not invalidate
/// views reading `inventory`, and vice versa. Extract a value snapshot with `snapshot()`
/// when writing to persistence.
@MainActor
@Observable
public final class PlayerStore {

    // MARK: - Identity

    public let id: UUID

    // MARK: - Basic Info

    public var name: String
    public var imageName: String
    public var fightStyle: FightStyle

    // MARK: - Progression

    public var currentExp: Int

    // MARK: - Farming Skills

    public var foragingExp: Int
    public var fishingExp: Int
    public var miningExp: Int

    // MARK: - Attributes

    public var fightStyleAttributes: HeroAttributes
    public var randomLevelAttributes: HeroAttributes

    // MARK: - Current Stats

    public var currentHP: Int16
    public var currentMP: Int16

    // MARK: - Equipment / Inventory

    public var equipped: EquippedItems
    public var inventory: ElfInventory

    // MARK: - Reputation

    public var reputation: Int

    // MARK: - Derived

    public var totalAttributes: HeroAttributes {
        HeroAttributes(
            hitPoints: fightStyleAttributes.hitPoints + randomLevelAttributes.hitPoints,
            manaPoints: fightStyleAttributes.manaPoints + randomLevelAttributes.manaPoints,
            agility: fightStyleAttributes.agility + randomLevelAttributes.agility,
            strength: fightStyleAttributes.strength + randomLevelAttributes.strength,
            power: fightStyleAttributes.power + randomLevelAttributes.power,
            instinct: fightStyleAttributes.instinct + randomLevelAttributes.instinct
        )
    }

    public var maxHP: Int16 { totalAttributes.hitPoints.value }
    public var maxMP: Int16 { totalAttributes.manaPoints.value }

    // MARK: - Initialization

    public init(from elf: ElfInfo) {
        self.id = elf.id
        self.name = elf.name
        self.imageName = elf.imageName
        self.fightStyle = elf.fightStyle
        self.currentExp = elf.currentExp
        self.foragingExp = elf.foragingExp
        self.fishingExp = elf.fishingExp
        self.miningExp = elf.miningExp
        self.fightStyleAttributes = elf.fightStyleAttributes
        self.randomLevelAttributes = elf.randomLevelAttributes
        self.currentHP = elf.currentHP
        self.currentMP = elf.currentMP
        self.equipped = elf.equipped
        self.inventory = elf.inventory
        self.reputation = elf.reputation
    }

    // MARK: - Snapshot

    public func snapshot() -> ElfInfo {
        ElfInfo(
            id: id,
            name: name,
            imageName: imageName,
            fightStyle: fightStyle,
            currentExp: currentExp,
            foragingExp: foragingExp,
            fishingExp: fishingExp,
            miningExp: miningExp,
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes,
            currentHP: currentHP,
            currentMP: currentMP,
            equipped: equipped,
            inventory: inventory,
            reputation: reputation
        )
    }
}
