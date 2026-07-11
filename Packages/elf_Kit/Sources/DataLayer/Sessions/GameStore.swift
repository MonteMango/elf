//
//  GameStore.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import Observation

/// Observable state container for an active game session. Holds session-bound
/// mutable state (action points, calendar, houses) as plain value types and
/// uses `@Observable` at the store level — any write through `houses[…]`
/// invalidates SwiftUI observers reading the same chain.
///
/// `Game` (value-type) is the on-disk / initial-creation shape; the store
/// lifts it into runtime via `init(from:)` (a trivial copy of `houses`) and
/// writes it back via `snapshot()` (also trivial — no per-elf mapping).
///
/// Mutations are restricted to the same module — the public surface is
/// read-only. `GameSession` (mutator/facade) lives inside `elf_Kit` so it has
/// `internal(set)` access; views in `elf_iOS` only read. `player` is an
/// `internal(set)` computed accessor that writes back into
/// `houses[playerHouseIndex].members[playerMemberIndex]`.
@MainActor
@Observable
public final class GameStore {

    // MARK: - Stable identity

    public let gameId: GameID
    public let playerHouseIndex: Int
    public let playerMemberIndex: Int

    // MARK: - Mutable state

    public internal(set) var currentDay: GameDay
    public internal(set) var calendar: [GameDay]
    public internal(set) var houses: [House]
    public internal(set) var playTime: TimeInterval

    /// Computed accessor for the player elf. Reads return a value copy of
    /// `houses[playerHouseIndex].members[playerMemberIndex]`; writes
    /// (including `state.player.X = Y` and `state.player.currentExp += n`,
    /// which Swift expands to read-modify-write through this property) flow
    /// back into the same slot, triggering `@Observable` invalidation on
    /// `houses`. The setter is `internal` — same module as `GameSession`, the
    /// sole mutator — so `elf_iOS` can only read, matching
    /// `currentDay`/`calendar`/`houses`/`actionPoints`.
    public internal(set) var player: ElfInfo {
        get { houses[playerHouseIndex].members[playerMemberIndex] }
        set { houses[playerHouseIndex].members[playerMemberIndex] = newValue }
    }

    /// The player's action points. AP is stored per-elf (`ElfInfo.actionPoints`);
    /// the "player AP" surfaced to the UI and spent by activities is just the
    /// player elf's pool. AI elves' pools are reached via `houses[…].members[…]`.
    /// Writes flow back through `player`, triggering `@Observable` invalidation.
    public internal(set) var actionPoints: ActionPoints {
        get { player.actionPoints }
        set { player.actionPoints = newValue }
    }

    // MARK: - Initialization

    public init(from game: Game, playTime: TimeInterval = 0) {
        self.gameId = game.id
        self.currentDay = game.gameState.currentDay
        self.calendar = game.gameState.calendar
        self.houses = game.houses
        self.playerHouseIndex = game.playerHouseIndex
        self.playerMemberIndex = game.playerMemberIndex
        self.playTime = playTime
    }

    // MARK: - Derived

    public var isLastDay: Bool {
        guard let lastDay = calendar.last else { return false }
        return currentDay.dayNumber >= lastDay.dayNumber
    }

    public var upcomingDays: [GameDay] {
        guard let currentIndex = calendar.firstIndex(where: { $0.dayNumber == currentDay.dayNumber }) else {
            return []
        }
        let nextIndex = currentIndex + 1
        guard nextIndex < calendar.count else { return [] }
        let endIndex = min(nextIndex + GameMechanicsConstants.upcomingDaysCount, calendar.count)
        return Array(calendar[nextIndex..<endIndex])
    }

    // MARK: - Snapshot

    /// Reconstructs the current state as a value-type `Game`. Used when
    /// persisting — `GameSession.save()` calls this and writes the result
    /// through `gameRepository`. With `houses` already a `[House]`, this is
    /// a flat copy — no per-elf walk.
    public func snapshot() -> Game {
        Game(
            id: gameId,
            houses: houses,
            gameState: GameState(
                currentDay: currentDay,
                calendar: calendar
            ),
            playerHouseIndex: playerHouseIndex,
            playerMemberIndex: playerMemberIndex
        )
    }
}
