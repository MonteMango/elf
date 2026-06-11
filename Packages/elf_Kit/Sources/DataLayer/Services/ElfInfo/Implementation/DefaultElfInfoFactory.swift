//
//  DefaultElfInfoFactory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Dependencies
import Foundation

/// Default implementation of ElfInfoFactory
public final class DefaultElfInfoFactory: ElfInfoFactory {

    // MARK: - Dependencies (snapshotted at init)

    private let attributeService: any AttributeService
    private let itemsRepository: any ItemsRepository
    private let inventoryService: any InventoryService

    // MARK: - Constants

    private let aiNames = [
        "Aria", "Luna", "Stella", "Nova", "Aurora",
        "Celeste", "Lyra", "Iris", "Fern", "Willow",
        "Sage", "Ivy", "Rose", "Lily", "Violet",
        "Jade", "Pearl", "Ruby", "Amber", "Crystal"
    ]

    private let availableFightStyles: [FightStyle] = [.dodge, .crit, .def]

    // MARK: - Starter Equipment IDs

    private let defaultRobeId = UUID(uuidString: "55f10623-d3d9-4021-85c6-f52e08058e13").map(ItemID.init(rawValue:))
    private let defaultWeaponId = UUID(uuidString: "dfbd2742-5470-4f97-84ea-fb17b5f3a6d2").map(ItemID.init(rawValue:))

    // MARK: - Initialization

    public init() {
        @Dependency(\.attributeService) var attributeService
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.inventoryService) var inventoryService
        self.attributeService = attributeService
        self.itemsRepository = itemsRepository
        self.inventoryService = inventoryService
    }

    // MARK: - Private Helpers

    private func createDefaultWeapon() -> ElfWeaponItem? {
        guard let weaponId = defaultWeaponId,
              let weaponItem = itemsRepository.getHeroItem(weaponId) as? WeaponItem else {
            return nil
        }
        return ElfWeaponItem(weaponItem: weaponItem)
    }

    private func createDefaultShirt() -> ElfRobeItem? {
        guard let robeId = defaultRobeId,
              let robeItem = itemsRepository.getHeroItem(robeId) as? RobeItem else {
            return nil
        }
        return ElfRobeItem(robeItem: robeItem)
    }

    /// Creates default equipped items and inventory for new characters
    private func createDefaultEquipment() -> (equipped: EquippedItems, inventory: ElfInventory) {
        guard let weapon = createDefaultWeapon() else {
            fatalError("Default weapon (Recruit's Spear) not found in repository")
        }
        guard let twoHanded = ElfTwoHandedWeaponItem(weapon: weapon) else {
            fatalError("Default weapon (Recruit's Spear) must be two-handed")
        }
        let shirt = createDefaultShirt()

        var inventory = ElfInventory()
        inventory = inventoryService.addWeapon(weapon, to: inventory)
        if let shirt {
            inventory = inventoryService.addRobe(shirt, to: inventory)
        }

        let equipped = EquippedItems(
            weapons: .twoHanded(weapon: twoHanded),
            shirt: shirt
        )

        return (equipped, inventory)
    }

    // MARK: - ElfInfoFactory

    public func create(from character: PlayerCharacter) -> ElfInfo {
        let (equipped, inventory) = createDefaultEquipment()

        // New characters start at level 1 (currentExp = 0)
        return ElfInfo(
            id: ElfID(rawValue: character.id.rawValue),
            name: character.name,
            imageName: character.appearance.imageName,
            fightStyle: character.fightStyle,
            currentExp: 0,
            fightStyleAttributes: character.fightStyleAttributes,
            randomLevelAttributes: character.randomLevelAttributes,
            equipped: equipped,
            inventory: inventory,
            reputation: 0
        )
    }

    public func createRandomAI(level: Int) -> ElfInfo {
        let fightStyle = availableFightStyles.randomElement() ?? .dodge

        let fightStyleAttributes = attributeService.getAllFightStyleAttributes(
            for: fightStyle,
            at: Int16(level)
        )
        let randomLevelAttributes = attributeService.getAllRandomLevelAttributes(
            for: Int16(level)
        )

        let (equipped, inventory) = createDefaultEquipment()

        // Calculate currentExp for desired level
        let currentExp = level <= 1 ? 0 : level * 100

        return ElfInfo(
            name: aiNames.randomElement() ?? "AI",
            imageName: "elf_ai_\(Int.random(in: 1...10))",
            fightStyle: fightStyle,
            currentExp: currentExp,
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes,
            equipped: equipped,
            inventory: inventory
        )
    }
}
