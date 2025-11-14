//
//  ElfWeaponValidator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import Foundation

public final class ElfWeaponValidator: WeaponValidator {

    private let itemsRepository: ItemsRepository

    public init(itemsRepository: ItemsRepository) {
        self.itemsRepository = itemsRepository
    }

    public func validateAndResolve(
        selecting itemId: UUID?,
        for slot: HeroItemType,
        currentItems: [HeroItemType: UUID?]
    ) async -> [HeroItemType: UUID?] {

        var updatedItems = currentItems

        // If unequipping (nil), just clear the slot
        guard let itemId = itemId else {
            updatedItems[slot] = nil
            return updatedItems
        }

        // Get the item being selected
        guard let item = await itemsRepository.getHeroItem(itemId) else {
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

    /// Handles weapon selection and resolves conflicts with currently equipped items
    ///
    /// This method validates weapon hand usage and automatically resolves conflicts:
    /// - **Two-handed weapons** (`.both`): Clears the shields slot since both hands are required
    /// - **Primary weapons** (`.primary`): Compatible with shields, but clears secondary weapons from shields slot
    /// - **Secondary weapons** (`.secondary`): Compatible with both shields and other secondary weapons (dual-wield)
    ///
    /// - Parameters:
    ///   - item: The weapon item being equipped
    ///   - currentItems: Current equipment state
    /// - Returns: Updated equipment dictionary with resolved conflicts
    private func handleWeaponSelection(
        item: Item,
        currentItems: [HeroItemType: UUID?]
    ) async -> [HeroItemType: UUID?] {

        var updatedItems = currentItems

        guard let weapon = item as? WeaponItem else {
            return currentItems
        }

        // Set the weapon in weapons slot
        updatedItems[.weapons] = weapon.id

        // Check handUse and resolve conflicts
        switch weapon.handUse {
        case .both:
            // Two-handed weapon: clear shields slot
            updatedItems[.shields] = nil

        case .primary:
            // Primary weapon: check shields slot
            if let shieldsItemId = currentItems[.shields],
               let shieldsItemId = shieldsItemId,
               let shieldsItem = await itemsRepository.getHeroItem(shieldsItemId) {

                // If shields slot has a secondary weapon, clear it
                // Primary weapons are not compatible with secondary weapons
                if let shieldsWeapon = shieldsItem as? WeaponItem,
                   shieldsWeapon.handUse == .secondary {
                    updatedItems[.shields] = nil
                }
                // Shield is OK with primary weapon, keep it
            }

        case .secondary:
            // Secondary weapon: compatible with both shields and other secondary weapons
            // No changes needed to shields slot
            break
        }

        return updatedItems
    }

    /// Handles item selection in the shields slot (right hand)
    ///
    /// The shields slot can contain either a shield or a secondary weapon for dual-wielding.
    /// This method delegates to the appropriate handler based on item type.
    ///
    /// - Parameters:
    ///   - item: The item being equipped in shields slot (ShieldItem or WeaponItem)
    ///   - currentItems: Current equipment state
    /// - Returns: Updated equipment dictionary with resolved conflicts
    private func handleShieldSlotSelection(
        item: Item,
        currentItems: [HeroItemType: UUID?]
    ) async -> [HeroItemType: UUID?] {

        let updatedItems = currentItems

        // Shields slot can contain: shield OR secondary weapon
        if let shield = item as? ShieldItem {
            return await handleShieldSelection(
                shield: shield,
                currentItems: updatedItems
            )
        } else if let weapon = item as? WeaponItem {
            return await handleSecondaryWeaponInShieldSlot(
                weapon: weapon,
                currentItems: updatedItems
            )
        }

        return currentItems
    }

    /// Handles shield equipment and validates compatibility with currently equipped weapons
    ///
    /// Shields are incompatible with two-handed weapons. This method automatically:
    /// - Clears the weapons slot if a two-handed weapon is equipped
    /// - Allows shields with primary weapons (one hand + shield)
    /// - Allows shields with secondary weapons (one hand + shield)
    ///
    /// - Parameters:
    ///   - shield: The shield item being equipped
    ///   - currentItems: Current equipment state
    /// - Returns: Updated equipment dictionary with resolved conflicts
    private func handleShieldSelection(
        shield: ShieldItem,
        currentItems: [HeroItemType: UUID?]
    ) async -> [HeroItemType: UUID?] {

        var updatedItems = currentItems

        // Set shield in shields slot
        updatedItems[.shields] = shield.id

        // Check weapon compatibility
        if let weaponId = currentItems[.weapons],
           let weaponId = weaponId,
           let weapon = await itemsRepository.getHeroItem(weaponId) as? WeaponItem {

            // Two-handed weapons are not compatible with shields
            if weapon.handUse == .both {
                updatedItems[.weapons] = nil
            }
            // Primary and secondary weapons are OK with shields
        }

        return updatedItems
    }

    /// Handles secondary weapon placement in shields slot for dual-wielding
    ///
    /// This method enforces dual-wielding rules:
    /// - **Only secondary weapons** can be placed in shields slot for dual-wielding
    /// - **Primary or two-handed weapons**: If user tries to place them in shields slot, both slots are cleared
    ///   (this prevents invalid state and signals the user must select proper weapon type)
    /// - **Dual-wield validation**: When a secondary weapon is placed in shields slot, checks main weapon:
    ///   - If main weapon is primary or two-handed → clears main weapon (incompatible with dual-wield)
    ///   - If main weapon is also secondary → allows dual-wield configuration
    ///
    /// - Parameters:
    ///   - weapon: The weapon being placed in shields slot
    ///   - currentItems: Current equipment state
    /// - Returns: Updated equipment dictionary with resolved conflicts
    /// - Note: Clearing both slots when non-secondary weapon is selected prevents confusion and ensures valid state
    private func handleSecondaryWeaponInShieldSlot(
        weapon: WeaponItem,
        currentItems: [HeroItemType: UUID?]
    ) async -> [HeroItemType: UUID?] {

        var updatedItems = currentItems

        // Only secondary weapons can be in shields slot (for dual wielding)
        guard weapon.handUse == .secondary else {
            // Primary or both weapons clear everything
            updatedItems[.weapons] = nil
            updatedItems[.shields] = nil
            return updatedItems
        }

        // Set secondary weapon in shields slot
        updatedItems[.shields] = weapon.id

        // Check weapons slot
        if let weaponId = currentItems[.weapons],
           let weaponId = weaponId,
           let mainWeapon = await itemsRepository.getHeroItem(weaponId) as? WeaponItem {

            // Dual wielding only works with secondary weapons
            // If main weapon is primary or both, clear weapons slot
            if mainWeapon.handUse != .secondary {
                updatedItems[.weapons] = nil
            }
            // Secondary + secondary = dual wield, OK
        }

        return updatedItems
    }
}
