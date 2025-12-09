//
//  DefaultCombatantSnapshotBuilder.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.12.25.
//

import Foundation

public final class DefaultCombatantSnapshotBuilder: CombatantSnapshotBuilder {

    private let itemsRepository: ItemsRepository
    private let armorService: ArmorService

    public init(itemsRepository: ItemsRepository, armorService: ArmorService) {
        self.itemsRepository = itemsRepository
        self.armorService = armorService
    }

    // MARK: - CombatantSnapshotBuilder

    public func buildSnapshot(
        name: String,
        imageName: String,
        level: Int16,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes,
        selectedItems: [HeroItemType: UUID?]
    ) async -> CombatantSnapshot? {

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
        var leftWeapon: ElfWeaponItem?
        var rightWeapon: ElfWeaponItem?
        var shield: ElfShieldItem?

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
        let armorValuesInt16 = await armorService.getAllItemsArmor(for: equippedItemIds)
        let armorValues = armorValuesInt16.mapValues { Int($0) }

        // Aggregate attributes from fight style and random level bonuses
        let totalStrength = fightStyleAttributes.strength + randomLevelAttributes.strength
        let totalAgility = fightStyleAttributes.agility + randomLevelAttributes.agility
        let totalPower = fightStyleAttributes.power + randomLevelAttributes.power
        let totalIntuition = fightStyleAttributes.instinct + randomLevelAttributes.instinct
        let totalHP = fightStyleAttributes.hitPoints + randomLevelAttributes.hitPoints

        // Get weapon damage range
        let weapon = rightWeapon?.item as? WeaponItem
        let minAttack = Int(weapon?.minimumAttackPoint ?? 0)
        let maxAttack = Int(weapon?.maximumAttackPoint ?? 0)

        // Calculate attack and defense points
        let hasLeftWeapon = leftWeapon != nil
        let hasRightWeapon = rightWeapon != nil
        let hasShield = shield != nil

        let attackPoints: Int
        if hasLeftWeapon && hasRightWeapon {
            attackPoints = 2  // Dual wield
        } else {
            attackPoints = 1  // Single weapon or no weapon
        }

        let defensePoints = hasShield ? 3 : 2  // Base 2, +1 with shield

        // Build the CombatantSnapshot
        return CombatantSnapshot(
            sourceId: UUID(),
            name: name,
            imageName: imageName,
            combatantType: .elf,
            level: level,
            currentHP: Int(totalHP),
            maxHP: Int(totalHP),
            strength: Int(totalStrength),
            agility: Int(totalAgility),
            power: Int(totalPower),
            intuition: Int(totalIntuition),
            attackPoints: attackPoints,
            defensePoints: defensePoints,
            minimumAttack: minAttack,
            maximumAttack: maxAttack,
            armorValues: armorValues,
            helmetItem: helmetItem,
            glovesItem: glovesItem,
            shoesItem: shoesItem,
            upperBodyItem: upperBodyItem,
            bottomBodyItem: bottomBodyItem,
            robeItem: robeItem,
            leftWeaponItem: leftWeapon,
            rightWeaponItem: rightWeapon,
            shieldItem: shield,
            ringItem: ringItem,
            necklaceItem: necklaceItem,
            earringsItem: earringsItem
        )
    }

    public func buildSnapshot(from monster: Monster) -> CombatantSnapshot {
        // Map monster's parts protection to BodyPart keys
        let armorValues: [BodyPart: Int] = [
            .head: monster.partsProtection.head,
            .leftHand: monster.partsProtection.left,
            .body: monster.partsProtection.center,
            .rightHand: monster.partsProtection.right,
            .legs: monster.partsProtection.legs
        ]

        return CombatantSnapshot(
            sourceId: monster.id,
            name: monster.title,
            imageName: monster.imageName,
            combatantType: .monster,
            level: 1,  // Monsters don't have levels, default to 1
            currentHP: monster.hitPoints,
            maxHP: monster.hitPoints,
            strength: monster.strength,
            agility: monster.agility,
            power: monster.power,
            intuition: monster.intuition,
            attackPoints: monster.attackPoints,
            defensePoints: monster.defensePoints,
            minimumAttack: monster.minimumAttack,
            maximumAttack: monster.maximumAttack,
            armorValues: armorValues
            // Equipment is nil for monsters (for now)
        )
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

// MARK: - Sendable Conformance
extension DefaultCombatantSnapshotBuilder: @unchecked Sendable {}
