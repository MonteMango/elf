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
    public let level: Int16
    public let currentExp: Int
    public let expToNextLevel: Int
    public let fightStyleAttributes: HeroAttributes
    public let randomLevelAttributes: HeroAttributes
    public let currentHP: Int16
    public let currentMP: Int16

    // Equipment slots
    public let equippedWeapon: WeaponSaveData?
    public let equippedShield: ShieldSaveData?
    public let equippedHelmet: DefenseSaveData?
    public let equippedGloves: DefenseSaveData?
    public let equippedShoes: DefenseSaveData?
    public let equippedUpperBody: DefenseSaveData?
    public let equippedBottomBody: DefenseSaveData?
    public let equippedShirt: RobeSaveData?
    public let equippedRing: JewelrySaveData?
    public let equippedNecklace: JewelrySaveData?
    public let equippedEarrings: JewelrySaveData?

    public let inventory: InventorySaveData
    public let reputation: Int

    public init(from elf: ElfInfo) {
        self.id = elf.id
        self.name = elf.name
        self.imageName = elf.imageName
        self.fightStyle = elf.fightStyle
        self.level = elf.level
        self.currentExp = elf.currentExp
        self.expToNextLevel = elf.expToNextLevel
        self.fightStyleAttributes = elf.fightStyleAttributes
        self.randomLevelAttributes = elf.randomLevelAttributes
        self.currentHP = elf.currentHP
        self.currentMP = elf.currentMP

        // Convert equipment slots
        self.equippedWeapon = elf.equippedWeapon.map { WeaponSaveData(from: $0) }
        self.equippedShield = elf.equippedShield.map { ShieldSaveData(from: $0) }
        self.equippedHelmet = elf.equippedHelmet.map { DefenseSaveData(from: $0) }
        self.equippedGloves = elf.equippedGloves.map { DefenseSaveData(from: $0) }
        self.equippedShoes = elf.equippedShoes.map { DefenseSaveData(from: $0) }
        self.equippedUpperBody = elf.equippedUpperBody.map { DefenseSaveData(from: $0) }
        self.equippedBottomBody = elf.equippedBottomBody.map { DefenseSaveData(from: $0) }
        self.equippedShirt = elf.equippedShirt.map { RobeSaveData(from: $0) }
        self.equippedRing = elf.equippedRing.map { JewelrySaveData(from: $0) }
        self.equippedNecklace = elf.equippedNecklace.map { JewelrySaveData(from: $0) }
        self.equippedEarrings = elf.equippedEarrings.map { JewelrySaveData(from: $0) }

        self.inventory = InventorySaveData(from: elf.inventory)
        self.reputation = elf.reputation
    }

    /// Convert to ElfInfo using ItemsRepository
    /// - Throws: `GameSaveError.missingItemData` if any equipped item cannot be restored
    public func toElfInfo(itemsRepository: ItemsRepository) throws -> ElfInfo {
        // Restore equipped items with error handling
        let weapon = try restoreEquipment(equippedWeapon, type: "weapon", itemsRepository: itemsRepository)
        let shield = try restoreEquipment(equippedShield, type: "shield", itemsRepository: itemsRepository)
        let helmet = try restoreEquipment(equippedHelmet, type: "helmet", itemsRepository: itemsRepository)
        let gloves = try restoreEquipment(equippedGloves, type: "gloves", itemsRepository: itemsRepository)
        let shoes = try restoreEquipment(equippedShoes, type: "shoes", itemsRepository: itemsRepository)
        let upperBody = try restoreEquipment(equippedUpperBody, type: "upperBody", itemsRepository: itemsRepository)
        let bottomBody = try restoreEquipment(equippedBottomBody, type: "bottomBody", itemsRepository: itemsRepository)
        let shirt = try restoreEquipment(equippedShirt, type: "shirt", itemsRepository: itemsRepository)
        let ring = try restoreEquipment(equippedRing, type: "ring", itemsRepository: itemsRepository)
        let necklace = try restoreEquipment(equippedNecklace, type: "necklace", itemsRepository: itemsRepository)
        let earrings = try restoreEquipment(equippedEarrings, type: "earrings", itemsRepository: itemsRepository)

        return ElfInfo(
            id: id,
            name: name,
            imageName: imageName,
            fightStyle: fightStyle,
            level: level,
            currentExp: currentExp,
            expToNextLevel: expToNextLevel,
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes,
            currentHP: currentHP,
            currentMP: currentMP,
            equippedWeapon: weapon,
            equippedShield: shield,
            equippedHelmet: helmet,
            equippedGloves: gloves,
            equippedShoes: shoes,
            equippedUpperBody: upperBody,
            equippedBottomBody: bottomBody,
            equippedShirt: shirt,
            equippedRing: ring,
            equippedNecklace: necklace,
            equippedEarrings: earrings,
            inventory: try inventory.toElfInventory(itemsRepository: itemsRepository),
            reputation: reputation
        )
    }

    // MARK: - Private Helpers

    private func restoreEquipment(
        _ saveData: WeaponSaveData?,
        type: String,
        itemsRepository: ItemsRepository
    ) throws -> ElfWeaponItem? {
        guard let saveData else { return nil }
        guard let item = saveData.toElfWeaponItem(using: itemsRepository) else {
            throw GameSaveError.missingItemData(itemId: saveData.itemId, itemType: type)
        }
        return item
    }

    private func restoreEquipment(
        _ saveData: ShieldSaveData?,
        type: String,
        itemsRepository: ItemsRepository
    ) throws -> ElfShieldItem? {
        guard let saveData else { return nil }
        guard let item = saveData.toElfShieldItem(using: itemsRepository) else {
            throw GameSaveError.missingItemData(itemId: saveData.itemId, itemType: type)
        }
        return item
    }

    private func restoreEquipment(
        _ saveData: DefenseSaveData?,
        type: String,
        itemsRepository: ItemsRepository
    ) throws -> ElfDefenseItem? {
        guard let saveData else { return nil }
        guard let item = saveData.toElfDefenseItem(using: itemsRepository) else {
            throw GameSaveError.missingItemData(itemId: saveData.itemId, itemType: type)
        }
        return item
    }

    private func restoreEquipment(
        _ saveData: RobeSaveData?,
        type: String,
        itemsRepository: ItemsRepository
    ) throws -> ElfRobeItem? {
        guard let saveData else { return nil }
        guard let item = saveData.toElfRobeItem(using: itemsRepository) else {
            throw GameSaveError.missingItemData(itemId: saveData.itemId, itemType: type)
        }
        return item
    }

    private func restoreEquipment(
        _ saveData: JewelrySaveData?,
        type: String,
        itemsRepository: ItemsRepository
    ) throws -> ElfJewelryItem? {
        guard let saveData else { return nil }
        guard let item = saveData.toElfJewelryItem(using: itemsRepository) else {
            throw GameSaveError.missingItemData(itemId: saveData.itemId, itemType: type)
        }
        return item
    }
}
