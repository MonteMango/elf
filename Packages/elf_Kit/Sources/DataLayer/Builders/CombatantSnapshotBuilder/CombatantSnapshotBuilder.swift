//
//  CombatantSnapshotBuilder.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.12.25.
//

import Foundation

/// Builder protocol for creating CombatantSnapshot instances from various sources.
/// Unified builder for both elves and monsters.
public protocol CombatantSnapshotBuilder: Sendable {

    /// Build a CombatantSnapshot for a production combatant — an `ElfInfo` from
    /// the game roster. Uses `elf.totalAttributes` so the "how do we aggregate
    /// attributes" formula lives in exactly one place (`ElfInfo.totalAttributes`).
    ///
    /// `name`, `imageName`, and `equipped` are pulled from the elf; `level` is
    /// the only piece the caller still computes (via `ProgressionService`).
    ///
    /// The snapshot carries combat data only — equipment item refs and the
    /// UI-side slot map are not stored on it (PR-B). UI equipment lives on
    /// `Battle.equippedItemsByCombatantId`, assembled separately by the caller.
    ///
    /// - Parameters:
    ///   - elf: The `ElfInfo` to build a combatant snapshot from. `elf.equipped`
    ///     drives weapon placement, defense points, armor lookup, and the
    ///     equipment contribution to `baseHeroAttributes`. `elf.globalBuffs`
    ///     are NOT auto-read — pass them explicitly via `globalBuffs` so the
    ///     caller controls which buff context the snapshot inherits.
    ///   - level: Hero level (1-12), computed from `elf.currentExp` by the
    ///     caller's `ProgressionService`.
    ///   - globalBuffs: Pre-applied global-scope buffs for this combatant
    ///     (typically `elf.globalBuffs`).
    /// - Returns: Constructed `CombatantSnapshot`.
    func buildSnapshot(
        elf: ElfInfo,
        level: Int,
        globalBuffs: [AppliedBuff]
    ) -> CombatantSnapshot

    /// Build a CombatantSnapshot from synthetic attribute components. Used by
    /// the dev `BattleSetupViewModel`, where the player/bot are not real
    /// `ElfInfo` instances from the roster — they're dev-screen state. Caller
    /// supplies pre-computed `fightStyleAttributes` and `randomLevelAttributes`
    /// directly; the builder still aggregates with `equipped.attributes` for the
    /// initial `baseHeroAttributes`.
    ///
    /// Prefer `buildSnapshot(elf:level:globalBuffs:)` for any path that has a
    /// real `ElfInfo` — this overload is the dev/synthetic-only escape hatch.
    func buildSnapshot(
        name: String,
        imageName: String,
        level: Int,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes,
        equipped: EquippedItems,
        globalBuffs: [AppliedBuff]
    ) -> CombatantSnapshot

    /// Build a CombatantSnapshot from a Monster.
    ///
    /// `globalBuffs` are folded into the monster's effective HP/MP at
    /// construction (mirroring the elf overload) and propagated into the
    /// snapshot so combat math reads them via
    /// `BuffEffectsCalculator.effectiveAttributes(of:)`. Pass `[]` for
    /// vanilla monsters; supply a non-empty array for bosses or elites that
    /// spawn with pre-applied modifiers.
    /// - Parameters:
    ///   - monster: The Monster to create a snapshot from
    ///   - globalBuffs: Pre-applied global-scope buffs (frozen for the
    ///     battle's duration once the snapshot is built).
    /// - Returns: A CombatantSnapshot representing the monster's combat state
    func buildSnapshot(from monster: Monster, globalBuffs: [AppliedBuff]) -> CombatantSnapshot
}
