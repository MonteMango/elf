//
//  HeroEquippedSlotResolver.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Maps `EquippedItems` to the `[HeroItemType: HeroEquippedSlot]` dictionary
/// consumed by `HeroSection` (Game Day), `SquadElfCell` (Dungeon → Squad) and
/// `CombatantBodyView` (Battle Fight). Resolves per-slot asset names and
/// inserts the off-hand mirror entry for two-handed weapons so all three
/// screens render the off-hand cell consistently.
///
/// `Sendable` so it can run inside the snapshot builder (non-MainActor) as
/// well as in `@MainActor` ViewModels.
public protocol HeroEquippedSlotResolver: Sendable {
    func resolve(equipped: EquippedItems) -> [HeroItemType: HeroEquippedSlot]
}
