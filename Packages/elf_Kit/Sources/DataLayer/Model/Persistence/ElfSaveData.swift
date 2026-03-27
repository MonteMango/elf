//
//  ElfSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

public struct ElfSaveData: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let imageName: String
    public let fightStyle: FightStyle
    public let currentExp: Int
    public let foragingExp: Int
    public let fishingExp: Int
    public let miningExp: Int
    public let fightStyleAttributes: HeroAttributes
    public let randomLevelAttributes: HeroAttributes
    public let currentHP: Int16
    public let currentMP: Int16

    // Equipment (new unified structure)
    public let equipped: EquippedItemsSaveData

    public let inventory: InventorySaveData
    public let reputation: Int

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

        // Convert equipment
        self.equipped = EquippedItemsSaveData(from: elf.equipped)

        self.inventory = InventorySaveData(from: elf.inventory)
        self.reputation = elf.reputation
    }

    /// Convert to ElfInfo using ItemsRepository and InventoryService
    public func toElfInfo(
        itemsRepository: ItemsRepository,
        inventoryService: InventoryService
    ) async throws -> ElfInfo {
        let restoredEquipped = await equipped.toEquippedItems(using: itemsRepository)
        let restoredInventory = try await inventory.toElfInventory(
            itemsRepository: itemsRepository,
            inventoryService: inventoryService
        )
        return ElfInfo(
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
            equipped: restoredEquipped,
            inventory: restoredInventory,
            reputation: reputation
        )
    }
}
