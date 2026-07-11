//
//  DungeonLifecycleMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Rule family for a dungeon run's session lifecycle, extracted from
/// `GameSession`'s Dungeon Session Lifecycle logic (T11): starting a run,
/// flushing accrued rewards into the player, banking on death, and
/// finishing/discarding a run. `GameSession` stays the single *owner* of
/// `dungeonSession` — it delegates every lifecycle transition here and writes
/// back the returned session.
@MainActor
public protocol DungeonLifecycleMutator: Sendable {

    /// Creates a new `DungeonSession` for the given dungeon and party.
    func startDungeonSession(gameStore: GameStore, dungeonId: DungeonID, allyIds: [ElfID]) -> DungeonSession

    /// Low-level teardown — always returns `nil`, the "no active session"
    /// value `GameSession` writes back to `dungeonSession`.
    func releaseDungeonSession() -> DungeonSession?

    /// Flushes a run reward ledger into the player and empties it. Shared by
    /// the run-end flush and the on-death bank; clearing keeps it idempotent
    /// so a later flush of the same (now-empty) ledger grants nothing.
    func flushRewards(from dungeonSession: DungeonSession, into gameStore: GameStore)

    /// Banks the run's rewards into the player *immediately on hero death*,
    /// while keeping the session alive for the result screen. No-op if there
    /// is no active session.
    func bankDungeonRewardsOnDeath(dungeonSession: DungeonSession?, into gameStore: GameStore)

    /// Ends a *completed* dungeon run: flushes the run's accrued rewards into
    /// the player, then releases the session. Returns the new value for
    /// `GameSession.dungeonSession` (always `nil`). No-op — and returns
    /// `nil` — if there is no active session.
    func finishDungeonRun(dungeonSession: DungeonSession?, into gameStore: GameStore) -> DungeonSession?

    /// Discards a dungeon run *without* granting any rewards. Returns the new
    /// value for `GameSession.dungeonSession` (always `nil`).
    func discardDungeonRun() -> DungeonSession?
}
