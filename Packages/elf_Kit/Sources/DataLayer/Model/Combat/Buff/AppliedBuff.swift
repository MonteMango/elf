//
//  AppliedBuff.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// A concrete instance of a catalog `Buff` attached to either an `ElfInfo`
/// (`.global` scope) or a `CombatantSnapshot` (`.battle` scope).
///
/// Scope is NOT encoded in this type — it lives on the catalog `Buff.scope`
/// reachable via `BuffsRepository.getById(buffId)`. Placement enforces the
/// invariant: anything in `ElfInfo.globalBuffs` / `CombatantSnapshot.globalBuffs`
/// is `.global`, anything in `CombatantSnapshot.battleBuffs` is `.battle`. The
/// chokepoint that upholds this is `BuffApplicationService` (asserts on
/// mismatched scope in DEBUG).
///
/// References the catalog `Buff` by `buffId` (ID-Reference); the full buff is
/// resolved through `BuffsRepository` at the use site.
public struct AppliedBuff: Sendable, Codable, Hashable, Identifiable {

    /// Per-instance identifier for diffing / UI.
    public let id: UUID

    /// Foreign key to `Buff.id` in `BuffsRepository`.
    public let buffId: UUID

    /// Game day on which this buff was applied. Combined with `Buff.durationDays`
    /// for expiry checks during day advance. Set to a concrete `Int` for
    /// `.global`-scope buffs; `nil` for `.battle`-scope buffs (which never
    /// expire by day — they're discarded with the snapshot at `finishBattle`).
    /// `nil` is enforced at the chokepoint: `BuffApplicationService.applyAsBattle`
    /// writes `nil`; `applyAsGlobal` writes the current day.
    public var appliedOnDay: Int?

    /// Stack count for `.stack` stacking rule. Always >= 1.
    public var stacks: Int

    public init(
        id: UUID = UUID(),
        buffId: UUID,
        appliedOnDay: Int? = nil,
        stacks: Int = 1
    ) {
        self.id = id
        self.buffId = buffId
        self.appliedOnDay = appliedOnDay
        self.stacks = max(1, stacks)
    }
}
