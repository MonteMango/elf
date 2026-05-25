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

    // Equipment (new unified structure)
    public let equipped: EquippedItemsSaveData

    public let inventory: InventorySaveData
    public let reputation: Int
    public let globalBuffs: [AppliedBuff]

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

        // Convert equipment
        self.equipped = EquippedItemsSaveData(from: elf.equipped)

        self.inventory = InventorySaveData(from: elf.inventory)
        self.reputation = elf.reputation
        self.globalBuffs = elf.globalBuffs
    }

    /// Convert to ElfInfo using ItemsRepository and InventoryService
    public func toElfInfo(
        itemsRepository: ItemsRepository,
        inventoryService: InventoryService
    ) throws -> ElfInfo {
        let restoredEquipped = equipped.toEquippedItems(using: itemsRepository)
        let restoredInventory = try inventory.toElfInventory(
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
            equipped: restoredEquipped,
            inventory: restoredInventory,
            reputation: reputation,
            globalBuffs: globalBuffs
        )
    }
}
