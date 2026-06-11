//
//  BuffApplicationService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Single source of truth for folding a new buff application into an existing
/// applied-buff collection according to the catalog buff's `stackingRule`.
///
/// `AppliedBuff` carries no scope tag — scope is enforced here, at the
/// chokepoint. `applyAsGlobal` accepts only `.global`-scope buffs;
/// `applyAsBattle` accepts only `.battle`-scope buffs. A mismatched `buffId`
/// is a no-op (with `assertionFailure` in DEBUG so the dev catches the bug).
/// The two methods remain separate so the placement intent at the call site
/// ("write to `ElfInfo.globalBuffs`" vs "write to `CombatantSnapshot.battleBuffs`")
/// stays explicit.
public protocol BuffApplicationService: Sendable {

    /// Apply a `.global`-scope buff to `buffs`. Returns the updated collection,
    /// or the input unchanged when the buff is unknown, `.ignore`-stacked, or
    /// has the wrong scope (latter triggers `assertionFailure` in DEBUG).
    /// - Parameters:
    ///   - buffId: Catalog buff id (`Buff.id`) to apply. Must reference a
    ///     buff with `scope == .global`.
    ///   - buffs: Existing global-buff collection (typically `ElfInfo.globalBuffs`).
    ///   - currentDay: Day number recorded on the new/refreshed buff.
    func applyAsGlobal(
        buffId: BuffID,
        to buffs: [AppliedBuff],
        currentDay: Int
    ) -> [AppliedBuff]

    /// Apply a `.battle`-scope buff to `buffs`. Returns the updated collection,
    /// or the input unchanged when the buff is unknown, `.ignore`-stacked, or
    /// has the wrong scope (latter triggers `assertionFailure` in DEBUG).
    ///
    /// No `currentDay` parameter — battle-scope buffs don't expire by day
    /// (they live and die with the snapshot), so `AppliedBuff.appliedOnDay`
    /// is set to `nil` for them.
    /// - Parameters:
    ///   - buffId: Catalog buff id (`Buff.id`) to apply. Must reference a
    ///     buff with `scope == .battle`.
    ///   - buffs: Existing battle-buff collection (typically `CombatantSnapshot.battleBuffs`).
    func applyAsBattle(
        buffId: BuffID,
        to buffs: [AppliedBuff]
    ) -> [AppliedBuff]
}
