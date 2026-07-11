//
//  RosterProgressionMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Rule family for roster progression, extracted from `GameSession` (T8):
/// the Roster Progression MARK's `addExperience`/`addDrops` logic (any elf).
/// `GameSession` stays the single *owner* of player/roster state — it
/// delegates the computation to this mutator and applies the returned value
/// itself.
public protocol RosterProgressionMutator: Sendable {

    /// Computes the new experience total after adding `amount` to
    /// `currentExp`. Pure computation only — does not mutate any state.
    func addExperience(_ amount: Int, to currentExp: Int) -> Int

    /// Computes the inventory that results from adding the given drops
    /// (materials, weapons, armor) to `inventory`. Pure computation only —
    /// does not mutate any state.
    func addDrops(
        materials: [MaterialReward],
        weapons: [ElfWeaponItem],
        armor: [ElfDefenseItem],
        to inventory: ElfInventory
    ) -> ElfInventory
}
