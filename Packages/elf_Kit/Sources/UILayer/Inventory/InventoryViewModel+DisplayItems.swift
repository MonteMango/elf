//
//  InventoryViewModel+DisplayItems.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Build Display Items

extension InventoryViewModel {

    /// Builds all display items from the player's current inventory & equipment.
    /// Reads only `inventory` and `equipped` from `PlayerStore` so SwiftUI observation
    /// is scoped to those two fields (avoids invalidation on unrelated changes like HP).
    func buildDisplayItems() -> [InventoryItemDisplay] {
        let inventory = gameService.player.inventory
        let equipped = gameService.player.equipped

        var items: [InventoryItemDisplay] = []

        for weapon in inventory.weapons {
            items.append(buildWeaponDisplayItem(weapon, equipped: equipped))
        }
        for shield in inventory.shields {
            items.append(buildShieldDisplayItem(shield, equipped: equipped))
        }
        for armor in inventory.armor {
            items.append(buildArmorDisplayItem(armor, equipped: equipped))
        }
        for robe in inventory.robes {
            items.append(buildRobeDisplayItem(robe, equipped: equipped))
        }
        for jewelry in inventory.jewelry {
            items.append(buildJewelryDisplayItem(jewelry, equipped: equipped))
        }
        for material in inventory.materials {
            if let displayItem = buildMaterialDisplayItem(material) {
                items.append(displayItem)
            }
        }

        return items
    }

    private func buildWeaponDisplayItem(_ weapon: ElfWeaponItem, equipped: EquippedItems) -> InventoryItemDisplay {
        let isEquipped = equipmentQueryService.isItemEquipped(weapon.id, in: equipped)
        // A weapon may only be unequipped when dual-wielding (game rule: at least one weapon always equipped).
        let isDualWield: Bool
        if case .dualWield = equipped.weapons { isDualWield = true } else { isDualWield = false }
        let canUnequip = isEquipped && isDualWield

        guard let weaponItem = weapon.item as? WeaponItem else {
            return InventoryItemDisplay(
                id: weapon.id,
                title: "Unknown Weapon",
                imageName: "weapon_unknown",
                isEquipped: isEquipped,
                canUnequip: canUnequip,
                category: .weapons,
                itemDetails: .weapon(WeaponAttributes(attackMin: 0, attackMax: 0, attackPoints: 1, handUse: "unknown"))
            )
        }

        let handUseString: String
        switch weaponItem.handUse {
        case .oneHand: handUseString = "one hand"
        case .both: handUseString = "two hands"
        }

        return InventoryItemDisplay(
            id: weapon.id,
            title: weaponItem.title,
            imageName: weaponItem.id.uuidString.lowercased(),
            isEquipped: isEquipped,
            canUnequip: canUnequip,
            category: .weapons,
            itemDetails: .weapon(WeaponAttributes(
                attackMin: Int(weaponItem.minimumAttackPoint),
                attackMax: Int(weaponItem.maximumAttackPoint),
                attackPoints: 1,
                handUse: handUseString,
                strength: Int(weaponItem.strength ?? 0),
                agility: Int(weaponItem.agility ?? 0),
                power: Int(weaponItem.power ?? 0),
                instinct: Int(weaponItem.instinct ?? 0),
                endurance: Int(weaponItem.endurance ?? 0),
                hitPoints: Int(weaponItem.hitPoints ?? 0),
                enchantLevel: weapon.enchantLevel > 0 ? weapon.enchantLevel : nil
            ))
        )
    }

    private func buildShieldDisplayItem(_ shield: ElfShieldItem, equipped: EquippedItems) -> InventoryItemDisplay {
        let isEquipped = equipmentQueryService.isItemEquipped(shield.id, in: equipped)

        guard let shieldItem = shield.item as? ShieldItem else {
            return InventoryItemDisplay(
                id: shield.id,
                title: "Unknown Shield",
                imageName: "shield_unknown",
                isEquipped: isEquipped,
                canUnequip: isEquipped,
                category: .weapons,
                itemDetails: .shield(ShieldAttributes(defense: 0))
            )
        }

        return InventoryItemDisplay(
            id: shield.id,
            title: shieldItem.title,
            imageName: shieldItem.id.uuidString.lowercased(),
            isEquipped: isEquipped,
            canUnequip: isEquipped,
            category: .weapons,
            itemDetails: .shield(ShieldAttributes(
                defense: Int(shieldItem.physicalDefensePoint),
                blockPoints: 1,
                strength: Int(shieldItem.strength ?? 0),
                agility: Int(shieldItem.agility ?? 0),
                endurance: Int(shieldItem.endurance ?? 0),
                hitPoints: Int(shieldItem.hitPoints ?? 0)
            ))
        )
    }

    private func buildArmorDisplayItem(_ armor: ElfDefenseItem, equipped: EquippedItems) -> InventoryItemDisplay {
        let isEquipped = equipmentQueryService.isItemEquipped(armor.id, in: equipped)

        guard let defenseItem = armor.item as? DefenseItem else {
            return InventoryItemDisplay(
                id: armor.id,
                title: "Unknown Armor",
                imageName: "armor_unknown",
                isEquipped: isEquipped,
                canUnequip: isEquipped,
                category: .armor,
                itemDetails: .armor(ArmorAttributes(defense: 0))
            )
        }

        return InventoryItemDisplay(
            id: armor.id,
            title: defenseItem.title,
            imageName: defenseItem.id.uuidString.lowercased(),
            isEquipped: isEquipped,
            canUnequip: isEquipped,
            category: .armor,
            itemDetails: .armor(ArmorAttributes(
                defense: Int(defenseItem.physicalDefensePoint),
                protectedParts: defenseItem.protectParts.map { $0.rawValue },
                strength: Int(defenseItem.strength ?? 0),
                agility: Int(defenseItem.agility ?? 0),
                power: Int(defenseItem.power ?? 0),
                instinct: Int(defenseItem.instinct ?? 0),
                endurance: Int(defenseItem.endurance ?? 0),
                hitPoints: Int(defenseItem.hitPoints ?? 0)
            ))
        )
    }

    private func buildRobeDisplayItem(_ robe: ElfRobeItem, equipped: EquippedItems) -> InventoryItemDisplay {
        let isEquipped = equipmentQueryService.isItemEquipped(robe.id, in: equipped)

        guard let robeItem = robe.item as? RobeItem else {
            return InventoryItemDisplay(
                id: robe.id,
                title: "Unknown Robe",
                imageName: "robe_unknown",
                isEquipped: isEquipped,
                canUnequip: isEquipped,
                category: .armor,
                itemDetails: .armor(ArmorAttributes(defense: 0))
            )
        }

        return InventoryItemDisplay(
            id: robe.id,
            title: robeItem.title,
            imageName: robeItem.id.uuidString.lowercased(),
            isEquipped: isEquipped,
            canUnequip: isEquipped,
            category: .armor,
            itemDetails: .armor(ArmorAttributes(
                defense: 0,
                protectedParts: ["torso"],
                strength: Int(robeItem.strength ?? 0),
                agility: Int(robeItem.agility ?? 0),
                power: Int(robeItem.power ?? 0),
                instinct: Int(robeItem.instinct ?? 0),
                endurance: Int(robeItem.endurance ?? 0),
                hitPoints: Int(robeItem.hitPoints ?? 0)
            ))
        )
    }

    private func buildJewelryDisplayItem(_ jewelry: ElfJewelryItem, equipped: EquippedItems) -> InventoryItemDisplay {
        let isEquipped = equipmentQueryService.isItemEquipped(jewelry.id, in: equipped)

        guard let jewelryItem = jewelry.item as? JewelryItem else {
            return InventoryItemDisplay(
                id: jewelry.id,
                title: "Unknown Jewelry",
                imageName: "jewelry_unknown",
                isEquipped: isEquipped,
                canUnequip: isEquipped,
                category: .armor,
                itemDetails: .jewelry(JewelryAttributes())
            )
        }

        return InventoryItemDisplay(
            id: jewelry.id,
            title: jewelryItem.title,
            imageName: jewelryItem.id.uuidString.lowercased(),
            isEquipped: isEquipped,
            canUnequip: isEquipped,
            category: .armor,
            itemDetails: .jewelry(JewelryAttributes(
                magicDefense: Int(jewelryItem.magicalDefensePoint),
                strength: Int(jewelryItem.strength ?? 0),
                agility: Int(jewelryItem.agility ?? 0),
                power: Int(jewelryItem.power ?? 0),
                instinct: Int(jewelryItem.instinct ?? 0),
                endurance: Int(jewelryItem.endurance ?? 0),
                hitPoints: Int(jewelryItem.hitPoints ?? 0),
                manaPoints: Int(jewelryItem.manaPoints ?? 0)
            ))
        )
    }

    private func buildMaterialDisplayItem(_ material: InventoryMaterial) -> InventoryItemDisplay? {
        switch material.source {
        case .monster:
            guard let data = materialRepository.getById(id: material.id) else { return nil }
            return InventoryItemDisplay(
                id: material.id,
                title: data.title,
                imageName: data.imageName,
                quantity: material.quantity,
                category: .materials,
                itemDetails: .material(MaterialAttributes(
                    description: data.description,
                    subcategory: data.category
                ))
            )

        case .fish:
            guard let data = fishRepository.getById(id: FishID(rawValue: material.id)) else { return nil }
            return InventoryItemDisplay(
                id: material.id,
                title: data.title,
                imageName: data.imageName,
                quantity: material.quantity,
                category: .materials,
                itemDetails: .material(MaterialAttributes(
                    description: data.description,
                    subcategory: .fish
                ))
            )

        case .herb:
            guard let data = herbRepository.getById(id: HerbID(rawValue: material.id)) else { return nil }
            return InventoryItemDisplay(
                id: material.id,
                title: data.title,
                imageName: data.imageName,
                quantity: material.quantity,
                category: .materials,
                itemDetails: .material(MaterialAttributes(
                    description: data.description,
                    subcategory: .herbs
                ))
            )

        case .ore:
            guard let data = oreRepository.getById(id: OreID(rawValue: material.id)) else { return nil }
            return InventoryItemDisplay(
                id: material.id,
                title: data.title,
                imageName: data.imageName,
                quantity: material.quantity,
                category: .materials,
                itemDetails: .material(MaterialAttributes(
                    description: data.description,
                    subcategory: .ores
                ))
            )
        }
    }
}
