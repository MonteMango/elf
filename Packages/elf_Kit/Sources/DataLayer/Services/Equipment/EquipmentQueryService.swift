//
//  EquipmentQueryService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Service for querying equipment state
///
/// Provides query methods extracted from EquippedItems and WeaponConfiguration models.
/// These methods don't mutate state, they only read and compute values.
public protocol EquipmentQueryService: Sendable {

    // MARK: - Item Checks

    /// Checks if the given owned-instance item ID is equipped anywhere
    func isItemEquipped(_ itemId: OwnedItemID, in equipped: EquippedItems) -> Bool

    // MARK: - Slot Queries

    /// Get equipped instance item ID for a slot
    func equippedItemId(for slot: HeroItemType, in equipped: EquippedItems) -> OwnedItemID?

    /// Get all equipped base (catalog) item IDs as dictionary (for UI compatibility)
    func equippedBaseItemIds(from equipped: EquippedItems) -> [HeroItemType: ItemID]
}
