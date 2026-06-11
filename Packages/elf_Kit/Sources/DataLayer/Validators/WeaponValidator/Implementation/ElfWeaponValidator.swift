//
//  ElfWeaponValidator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import Dependencies
import Foundation

public final class ElfWeaponValidator: WeaponValidator {

    private let itemsRepository: any ItemsRepository

    public init() {
        @Dependency(\.itemsRepository) var itemsRepository
        self.itemsRepository = itemsRepository
    }

    public func validateAndResolve(
        selecting itemId: ItemID?,
        for slot: HeroItemType,
        currentItems: [HeroItemType: ItemID?]
    ) async -> [HeroItemType: ItemID?] {

        var updatedItems = currentItems

        // If unequipping (nil), just clear the slot
        guard let itemId = itemId else {
            updatedItems[slot] = nil
            return updatedItems
        }

        // Pass-through for other slots (only weapons and shields need validation)
        guard slot == .weapons || slot == .shields else {
            updatedItems[slot] = itemId
            return updatedItems
        }

        // Get the item being selected
        guard let item = itemsRepository.getHeroItem(itemId) else {
            return currentItems
        }

        switch slot {
        case .weapons:
            updatedItems = await handleWeaponSelection(
                item: item,
                currentItems: updatedItems
            )

        case .shields:
            updatedItems = await handleShieldSlotSelection(
                item: item,
                currentItems: updatedItems
            )

        default:
            // Other slots don't need validation
            updatedItems[slot] = itemId
        }

        return updatedItems
    }

    // MARK: - Private Methods

    /// Handles weapon selection in the weapons slot.
    /// After the `.primary`/`.secondary` merge the only cross-slot rule left is:
    /// a two-handed weapon occupies both hands and forces the shields slot empty.
    /// One-handed weapons coexist freely with anything in `.shields` (shield or
    /// another one-handed weapon for dual-wield).
    private func handleWeaponSelection(
        item: Item,
        currentItems: [HeroItemType: ItemID?]
    ) async -> [HeroItemType: ItemID?] {

        var updatedItems = currentItems

        guard let weapon = item as? WeaponItem else {
            return currentItems
        }

        updatedItems[.weapons] = weapon.id

        if weapon.handUse == .both {
            updatedItems[.shields] = nil
        }

        return updatedItems
    }

    /// Handles item selection in the shields slot (off-hand).
    /// The slot accepts either a shield or a one-handed weapon (for dual-wielding) and
    /// delegates to the appropriate handler.
    private func handleShieldSlotSelection(
        item: Item,
        currentItems: [HeroItemType: ItemID?]
    ) async -> [HeroItemType: ItemID?] {

        let updatedItems = currentItems

        // Shields slot can contain: shield OR one-handed weapon
        if let shield = item as? ShieldItem {
            return await handleShieldSelection(
                shield: shield,
                currentItems: updatedItems
            )
        } else if let weapon = item as? WeaponItem {
            return await handleWeaponInShieldSlot(
                weapon: weapon,
                currentItems: updatedItems
            )
        }

        return currentItems
    }

    /// Handles shield equipment. Shields are incompatible with two-handed weapons —
    /// the only conflict that survived the `WeaponHandUse` merge.
    private func handleShieldSelection(
        shield: ShieldItem,
        currentItems: [HeroItemType: ItemID?]
    ) async -> [HeroItemType: ItemID?] {

        var updatedItems = currentItems

        updatedItems[.shields] = shield.id

        if let weaponId = currentItems[.weapons],
           let weaponId = weaponId,
           let weapon = itemsRepository.getHeroItem(weaponId) as? WeaponItem,
           weapon.handUse == .both {
            updatedItems[.weapons] = nil
        }

        return updatedItems
    }

    /// Handles a weapon being placed into the shields slot for dual-wielding.
    /// After the merge any one-handed weapon is eligible. A two-handed weapon in this
    /// slot is structurally invalid (the items repository excludes them from the shields
    /// tab), so it is treated as an error and both slots are cleared.
    private func handleWeaponInShieldSlot(
        weapon: WeaponItem,
        currentItems: [HeroItemType: ItemID?]
    ) async -> [HeroItemType: ItemID?] {

        var updatedItems = currentItems

        guard weapon.handUse == .oneHand else {
            updatedItems[.weapons] = nil
            updatedItems[.shields] = nil
            return updatedItems
        }

        updatedItems[.shields] = weapon.id

        if let weaponId = currentItems[.weapons],
           let weaponId = weaponId,
           let mainWeapon = itemsRepository.getHeroItem(weaponId) as? WeaponItem,
           mainWeapon.handUse == .both {
            updatedItems[.weapons] = nil
        }

        return updatedItems
    }
}
