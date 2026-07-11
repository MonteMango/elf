//
//  DayCycleMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Pure rule family for a calendar-day advance, extracted from `GameSession`'s
/// Day Management logic (T10): resetting every elf's action points and
/// expiring global buffs whose duration has elapsed. `GameSession` stays the
/// single *owner* of state — it snapshots the current houses, delegates to
/// this stateless mutator, and writes the returned houses back.
public protocol DayCycleMutator: Sendable {

    /// Resets action points to maximum for every elf in every house, and
    /// removes expired global buffs (`toDayNumber - appliedOnDay >= durationDays`).
    func advanceDay(houses: [House], toDayNumber: Int) -> [House]
}
