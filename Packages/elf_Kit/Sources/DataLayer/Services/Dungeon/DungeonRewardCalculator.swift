//
//  DungeonRewardCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Rolls the rewards for clearing a dungeon room — **one `HuntRewards` roll per
/// monster instance** (expanded by `MonsterRef.count`), summed across the room.
/// Pure policy (no run state); `DungeonSession` accrues the result into its
/// ledger. Fixes the old "only the first monster rewards" behaviour.
public protocol DungeonRewardCalculator: Sendable {
    func roomRewards(monsters: [MonsterRef]) -> [HuntRewards]
}
