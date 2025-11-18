//
//  ElfElfHeroBuilder.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import Foundation

public final class ElfElfHeroBuilder: ElfHeroBuilder {

    private let itemsRepository: ItemsRepository
    private let armorService: ArmorService

    public init(itemsRepository: ItemsRepository, armorService: ArmorService) {
        self.itemsRepository = itemsRepository
        self.armorService = armorService
    }

    public func buildElfHero(
        level: Int16,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes,
        selectedItems: [HeroItemType: UUID?]
    ) async -> ElfHero? {

        // Convert UUID items to Elf*Item types
        let helmetItem = await convertToElfDefenseItem(selectedItems[.helmet] ?? nil)
        let glovesItem = await convertToElfDefenseItem(selectedItems[.gloves] ?? nil)
        let shoesItem = await convertToElfDefenseItem(selectedItems[.shoes] ?? nil)
        let upperBodyItem = await convertToElfDefenseItem(selectedItems[.upperBody] ?? nil)
        let bottomBodyItem = await convertToElfDefenseItem(selectedItems[.bottomBody] ?? nil)

        let robeItem = await convertToElfRobeItem(selectedItems[.shirt] ?? nil)

        let weaponItem = await convertToElfWeaponItem(selectedItems[.weapons] ?? nil)

        let ringItem = await convertToElfJewelryItem(selectedItems[.ring] ?? nil)
        let necklaceItem = await convertToElfJewelryItem(selectedItems[.necklace] ?? nil)
        let earringsItem = await convertToElfJewelryItem(selectedItems[.earrings] ?? nil)

        // Determine weapon placement and shield
        // Shield slot can contain either a shield or a second weapon (dual wielding)
        var leftWeapon: ElfWeaponItem? = nil
        var rightWeapon: ElfWeaponItem? = nil
        var shield: ElfShieldItem? = nil

        if let weapon = weaponItem {
            // Check if it's a two-handed weapon
            if let weaponBaseItem = weapon.item as? WeaponItem,
               weaponBaseItem.handUse == .both {
                // Two-handed weapon goes to right hand only
                rightWeapon = weapon
            } else {
                // One-handed weapon goes to right hand
                rightWeapon = weapon

                // Check what's in the shield slot - could be weapon (dual wield) or shield
                if let shieldSlotItemId = selectedItems[.shields] ?? nil,
                   let shieldSlotItem = itemsRepository.getHeroItem(shieldSlotItemId) {
                    if shieldSlotItem is WeaponItem {
                        // Dual wielding - second weapon in left hand
                        leftWeapon = await convertToElfWeaponItem(shieldSlotItemId)
                    } else if shieldSlotItem is ShieldItem {
                        // Shield in shield slot
                        shield = await convertToElfShieldItem(shieldSlotItemId)
                    }
                }
            }
        } else {
            // No primary weapon, check if shield slot has a shield
            shield = await convertToElfShieldItem(selectedItems[.shields] ?? nil)
        }

        // Collect all equipped item IDs for armor calculation
        var equippedItemIds: [UUID] = []
        if let id = selectedItems[.helmet] ?? nil { equippedItemIds.append(id) }
        if let id = selectedItems[.gloves] ?? nil { equippedItemIds.append(id) }
        if let id = selectedItems[.shoes] ?? nil { equippedItemIds.append(id) }
        if let id = selectedItems[.upperBody] ?? nil { equippedItemIds.append(id) }
        if let id = selectedItems[.bottomBody] ?? nil { equippedItemIds.append(id) }
        if let id = selectedItems[.shirt] ?? nil { equippedItemIds.append(id) }
        if let id = selectedItems[.shields] ?? nil { equippedItemIds.append(id) }

        // Calculate armor values using ArmorService
        let armorValues = await armorService.getAllItemsArmor(for: equippedItemIds)

        // Build the ElfHero
        let elfHero = ElfHero(
            level: Int(level),
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes,
            helmetElfItem: helmetItem,
            glovesElfItem: glovesItem,
            shoesElfItem: shoesItem,
            upperBodyElfItem: upperBodyItem,
            bottomBodyElfItem: bottomBodyItem,
            robeElfItem: robeItem,
            leftHandWeaponElfItem: leftWeapon,
            rightHandWeaponElfItem: rightWeapon,
            shieldElfItem: shield,
            ringElfItem: ringItem,
            necklaceElfItem: necklaceItem,
            earringsElfItem: earringsItem,
            armorValues: armorValues
        )

        return elfHero
    }

    // MARK: - Private Conversion Methods

    private func convertToElfDefenseItem(_ itemId: UUID?) async -> ElfDefenseItem? {
        guard let itemId = itemId else { return nil }
        guard let item = itemsRepository.getHeroItem(itemId) else { return nil }
        guard item is DefenseItem else { return nil }

        return ElfDefenseItem(id: itemId, item: item)
    }

    private func convertToElfRobeItem(_ itemId: UUID?) async -> ElfRobeItem? {
        guard let itemId = itemId else { return nil }
        guard let item = itemsRepository.getHeroItem(itemId) else { return nil }
        guard item is RobeItem else { return nil }

        return ElfRobeItem(id: itemId, item: item)
    }

    private func convertToElfWeaponItem(_ itemId: UUID?) async -> ElfWeaponItem? {
        guard let itemId = itemId else { return nil }
        guard let item = itemsRepository.getHeroItem(itemId) else { return nil }
        guard item is WeaponItem else { return nil }

        return ElfWeaponItem(id: itemId, item: item, enchantLevel: 0)
    }

    private func convertToElfShieldItem(_ itemId: UUID?) async -> ElfShieldItem? {
        guard let itemId = itemId else { return nil }
        guard let item = itemsRepository.getHeroItem(itemId) else { return nil }
        guard item is ShieldItem else { return nil }

        return ElfShieldItem(id: itemId, item: item)
    }

    private func convertToElfJewelryItem(_ itemId: UUID?) async -> ElfJewelryItem? {
        guard let itemId = itemId else { return nil }
        guard let item = itemsRepository.getHeroItem(itemId) else { return nil }
        guard item is JewelryItem else { return nil }

        return ElfJewelryItem(id: itemId, item: item)
    }
}
