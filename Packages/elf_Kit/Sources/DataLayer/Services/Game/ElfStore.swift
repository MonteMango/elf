//
//  ElfStore.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import Observation

/// Observable wrapper over an `ElfInfo` value. Used uniformly for the player
/// elf and every AI house member at runtime — eliminates the historic
/// duplication where the player had a separate `PlayerStore` while AI elves
/// stayed as value-types in `house.members`.
///
/// Per-field SwiftUI observation: mutating `currentExp` does not invalidate
/// views reading `inventory`, and vice versa. Extract a value snapshot with
/// `snapshot()` when writing to persistence.
@MainActor
@Observable
public final class ElfStore {

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

    // MARK: - Equipment / Inventory

    public var equipped: EquippedItems
    public var inventory: ElfInventory

    // MARK: - Reputation

    public var reputation: Int

    // MARK: - Derived

    public var totalAttributes: HeroAttributes {
        fightStyleAttributes + randomLevelAttributes + equipped.attributes
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
            equipped: equipped,
            inventory: inventory,
            reputation: reputation
        )
    }
}
