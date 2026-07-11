//
//  DefaultRosterProgressionMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Default `RosterProgressionMutator`. Mirrors the rule formerly inlined on
/// `GameSession`'s Roster Progression MARK (`addExperience`/`addDrops`).
/// Collaborators are resolved lazily inside each method (not at init) so
/// simply constructing this mutator doesn't eagerly pull its live-only deps.
public final class DefaultRosterProgressionMutator: RosterProgressionMutator {

    // MARK: - Initialization

    public init() {}

    // MARK: - RosterProgressionMutator

    public func addExperience(_ amount: Int, to currentExp: Int) -> Int {
        currentExp + amount
    }

    public func addDrops(
        materials: [MaterialReward],
        weapons: [ElfWeaponItem],
        armor: [ElfDefenseItem],
        to inventory: ElfInventory
    ) -> ElfInventory {
        @Dependency(\.inventoryService) var inventoryService

        let additions = materials.map {
            MaterialAddition(ref: .monster($0.id), quantity: $0.amount)
        }
        var updatedInventory = inventoryService.addMaterials(additions, to: inventory)
        for weapon in weapons {
            updatedInventory = inventoryService.addWeapon(weapon, to: updatedInventory)
        }
        for armorPiece in armor {
            updatedInventory = inventoryService.addArmor(armorPiece, to: updatedInventory)
        }
        return updatedInventory
    }
}
