//
//  InventoryViewModel+DisplayItems.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Build Display Items

extension InventoryViewModel {

    func buildDisplayItems() -> [InventoryDisplayItem] {
        var items: [InventoryDisplayItem] = []

        let inventory = player.inventory
        let equipped = player.equipped

        // Weapons
        for weapon in inventory.weapons {
            items.append(buildWeaponDisplayItem(weapon, equipped: equipped))
        }

        // Shields
        for shield in inventory.shields {
            items.append(buildShieldDisplayItem(shield, equipped: equipped))
        }

        // Armor
        for armor in inventory.armor {
            items.append(buildArmorDisplayItem(armor, equipped: equipped))
        }

        // Robes
        for robe in inventory.robes {
            items.append(buildRobeDisplayItem(robe, equipped: equipped))
        }

        // Jewelry
        for jewelry in inventory.jewelry {
            items.append(buildJewelryDisplayItem(jewelry, equipped: equipped))
        }

        // Materials
        for material in inventory.materials {
            if let displayItem = buildMaterialDisplayItem(material) {
                items.append(displayItem)
            }
        }

        return items
    }

    private func buildWeaponDisplayItem(_ weapon: ElfWeaponItem, equipped: EquippedItems) -> InventoryDisplayItem {
        guard let weaponItem = weapon.item as? WeaponItem else {
            return InventoryDisplayItem(
                id: weapon.id,
                title: "Unknown Weapon",
                imageName: "weapon_unknown",
                isEquipped: equipped.isEquipped(weapon.id),
                category: .weapons,
                itemDetails: .weapon(WeaponDetails(attackMin: 0, attackMax: 0, attackPoints: 1, handUse: "unknown"))
            )
        }

        let handUseString: String
        switch weaponItem.handUse {
        case .primary: handUseString = "one hand"
        case .secondary: handUseString = "one hand (off-hand)"
        case .both: handUseString = "two hands"
        }

        return InventoryDisplayItem(
            id: weapon.id,
            title: weaponItem.title,
            imageName: weaponItem.id.uuidString.lowercased(),
            isEquipped: equipped.isEquipped(weapon.id),
            category: .weapons,
            itemDetails: .weapon(WeaponDetails(
                attackMin: Int(weaponItem.minimumAttackPoint),
                attackMax: Int(weaponItem.maximumAttackPoint),
                attackPoints: 1,
                handUse: handUseString,
                strength: Int(weaponItem.strength ?? 0),
                agility: Int(weaponItem.agility ?? 0),
                power: Int(weaponItem.power ?? 0),
                instinct: Int(weaponItem.instinct ?? 0),
                hitPoints: Int(weaponItem.hitPoints ?? 0),
                enchantLevel: weapon.enchantLevel > 0 ? weapon.enchantLevel : nil
            ))
        )
    }

    private func buildShieldDisplayItem(_ shield: ElfShieldItem, equipped: EquippedItems) -> InventoryDisplayItem {
        guard let shieldItem = shield.item as? ShieldItem else {
            return InventoryDisplayItem(
                id: shield.id,
                title: "Unknown Shield",
                imageName: "shield_unknown",
                isEquipped: equipped.isEquipped(shield.id),
                category: .weapons,
                itemDetails: .shield(ShieldDetails(defense: 0))
            )
        }

        return InventoryDisplayItem(
            id: shield.id,
            title: shieldItem.title,
            imageName: shieldItem.id.uuidString.lowercased(),
            isEquipped: equipped.isEquipped(shield.id),
            category: .weapons,
            itemDetails: .shield(ShieldDetails(
                defense: Int(shieldItem.physicalDefensePoint),
                blockPoints: 1,
                strength: Int(shieldItem.strength ?? 0),
                agility: Int(shieldItem.agility ?? 0),
                hitPoints: Int(shieldItem.hitPoints ?? 0)
            ))
        )
    }

    private func buildArmorDisplayItem(_ armor: ElfDefenseItem, equipped: EquippedItems) -> InventoryDisplayItem {
        guard let defenseItem = armor.item as? DefenseItem else {
            return InventoryDisplayItem(
                id: armor.id,
                title: "Unknown Armor",
                imageName: "armor_unknown",
                isEquipped: equipped.isEquipped(armor.id),
                category: .armor,
                itemDetails: .armor(ArmorDetails(defense: 0))
            )
        }

        return InventoryDisplayItem(
            id: armor.id,
            title: defenseItem.title,
            imageName: defenseItem.id.uuidString.lowercased(),
            isEquipped: equipped.isEquipped(armor.id),
            category: .armor,
            itemDetails: .armor(ArmorDetails(
                defense: Int(defenseItem.physicalDefensePoint),
                protectedParts: defenseItem.protectParts.map { $0.rawValue },
                strength: Int(defenseItem.strength ?? 0),
                agility: Int(defenseItem.agility ?? 0),
                power: Int(defenseItem.power ?? 0),
                instinct: Int(defenseItem.instinct ?? 0),
                hitPoints: Int(defenseItem.hitPoints ?? 0)
            ))
        )
    }

    private func buildRobeDisplayItem(_ robe: ElfRobeItem, equipped: EquippedItems) -> InventoryDisplayItem {
        guard let robeItem = robe.item as? RobeItem else {
            return InventoryDisplayItem(
                id: robe.id,
                title: "Unknown Robe",
                imageName: "robe_unknown",
                isEquipped: equipped.isEquipped(robe.id),
                category: .armor,
                itemDetails: .armor(ArmorDetails(defense: 0))
            )
        }

        return InventoryDisplayItem(
            id: robe.id,
            title: robeItem.title,
            imageName: robeItem.id.uuidString.lowercased(),
            isEquipped: equipped.isEquipped(robe.id),
            category: .armor,
            itemDetails: .armor(ArmorDetails(
                defense: 0,
                protectedParts: ["torso"],
                strength: Int(robeItem.strength ?? 0),
                agility: Int(robeItem.agility ?? 0),
                power: Int(robeItem.power ?? 0),
                instinct: Int(robeItem.instinct ?? 0),
                hitPoints: Int(robeItem.hitPoints ?? 0)
            ))
        )
    }

    private func buildJewelryDisplayItem(_ jewelry: ElfJewelryItem, equipped: EquippedItems) -> InventoryDisplayItem {
        guard let jewelryItem = jewelry.item as? JewelryItem else {
            return InventoryDisplayItem(
                id: jewelry.id,
                title: "Unknown Jewelry",
                imageName: "jewelry_unknown",
                isEquipped: equipped.isEquipped(jewelry.id),
                category: .armor,
                itemDetails: .jewelry(JewelryDetails())
            )
        }

        return InventoryDisplayItem(
            id: jewelry.id,
            title: jewelryItem.title,
            imageName: jewelryItem.id.uuidString.lowercased(),
            isEquipped: equipped.isEquipped(jewelry.id),
            category: .armor,
            itemDetails: .jewelry(JewelryDetails(
                magicDefense: Int(jewelryItem.magicalDefensePoint),
                strength: Int(jewelryItem.strength ?? 0),
                agility: Int(jewelryItem.agility ?? 0),
                power: Int(jewelryItem.power ?? 0),
                instinct: Int(jewelryItem.instinct ?? 0),
                hitPoints: Int(jewelryItem.hitPoints ?? 0),
                manaPoints: Int(jewelryItem.manaPoints ?? 0)
            ))
        )
    }

    private func buildMaterialDisplayItem(_ material: InventoryMaterial) -> InventoryDisplayItem? {
        guard let materialData = materialRepository.getMaterial(id: material.id) else {
            return nil
        }

        return InventoryDisplayItem(
            id: material.id,
            title: materialData.title,
            imageName: materialData.imageName,
            quantity: material.quantity,
            category: .materials,
            itemDetails: .material(MaterialDetails(description: "Material for crafting"))
        )
    }
}
