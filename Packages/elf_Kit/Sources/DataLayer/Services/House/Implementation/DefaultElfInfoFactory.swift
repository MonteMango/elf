//
//  DefaultElfInfoFactory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Default implementation of ElfInfoFactory
public final class DefaultElfInfoFactory: ElfInfoFactory {

    // MARK: - Dependencies

    private let attributeService: AttributeService
    private let itemsRepository: ItemsRepository

    // MARK: - Constants

    private let aiNames = [
        "Aria", "Luna", "Stella", "Nova", "Aurora",
        "Celeste", "Lyra", "Iris", "Fern", "Willow",
        "Sage", "Ivy", "Rose", "Lily", "Violet",
        "Jade", "Pearl", "Ruby", "Amber", "Crystal"
    ]

    private let availableFightStyles: [FightStyle] = [.dodge, .crit, .def]

    // MARK: - Starter Equipment IDs

    private let defaultRobeId = UUID(uuidString: "55f10623-d3d9-4021-85c6-f52e08058e13")
    private let defaultWeaponId = UUID(uuidString: "dfbd2742-5470-4f97-84ea-fb17b5f3a6d2")

    // MARK: - Initialization

    public init(attributeService: AttributeService, itemsRepository: ItemsRepository) {
        self.attributeService = attributeService
        self.itemsRepository = itemsRepository
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
        let shirt = createDefaultShirt()

        var inventory = ElfInventory()
        inventory.addWeapon(weapon)
        if let shirt {
            inventory.addRobe(shirt)
        }

        let equipped = EquippedItems(
            weapons: .twoHanded(weapon: weapon),
            shirt: shirt
        )

        return (equipped, inventory)
    }

    // MARK: - ElfInfoFactory

    public func create(from character: PlayerCharacter) -> ElfInfo {
        let (equipped, inventory) = createDefaultEquipment()

        // New characters start at level 1 (currentExp = 0)
        return ElfInfo(
            id: character.id,
            name: character.name,
            imageName: character.appearance.imageName,
            fightStyle: character.fightStyle,
            currentExp: 0,
            fightStyleAttributes: character.fightStyleAttributes,
            randomLevelAttributes: character.randomLevelAttributes,
            currentHP: character.totalAttributes.hitPoints.value,
            currentMP: character.totalAttributes.manaPoints.value,
            equipped: equipped,
            inventory: inventory,
            reputation: 0
        )
    }

    public func createRandomAI(level: Int) async -> ElfInfo {
        let fightStyle = availableFightStyles.randomElement()!

        // Use AttributeService like in BattleSetup
        let fightStyleAttributes = await attributeService.getAllFightStyleAttributes(
            for: fightStyle,
            at: Int16(level)
        )
        let randomLevelAttributes = await attributeService.getAllRandomLevelAttributes(
            for: Int16(level)
        )

        let totalHP = fightStyleAttributes.hitPoints + randomLevelAttributes.hitPoints
        let totalMP = fightStyleAttributes.manaPoints + randomLevelAttributes.manaPoints

        let (equipped, inventory) = createDefaultEquipment()

        // Calculate currentExp for desired level
        // level 1 → 0 XP, level N (N>1) → N*100 XP
        let currentExp = level <= 1 ? 0 : level * 100

        return ElfInfo(
            name: aiNames.randomElement()!,
            imageName: "elf_ai_\(Int.random(in: 1...10))",
            fightStyle: fightStyle,
            currentExp: currentExp,
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes,
            currentHP: totalHP.value,
            currentMP: totalMP.value,
            equipped: equipped,
            inventory: inventory
        )
    }
}
