//
//  GameStore.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import Observation

/// Observable state container for an active game session. Mirrors `PlayerStore`
/// for the game-level scope: holds all session-bound mutable state (action
/// points, calendar, houses, player), exposes per-property SwiftUI observation,
/// and produces a value-type `Game` snapshot for persistence.
///
/// Mutations are restricted to the same module — the public surface is
/// read-only. `DefaultGameService` (mutator) and `GameSession` (facade) live
/// inside `elf_Kit` so they have `internal(set)` access; views in `elf_iOS`
/// only read.
@MainActor
@Observable
public final class GameStore {

    // MARK: - Stable identity

    public let gameId: UUID
    public let playerHouseIndex: Int
    public let playerMemberIndex: Int

    // MARK: - Mutable state

    public internal(set) var actionPoints: ActionPoints
    public internal(set) var currentDay: GameDay
    public internal(set) var calendar: [GameDay]
    public internal(set) var houses: [House]
    public internal(set) var playTime: TimeInterval

    /// Nested observable store for the player elf — fields tracked granularly
    /// so mutating `currentExp` doesn't invalidate views reading `inventory`.
    public let player: PlayerStore

    // MARK: - Initialization

    public init(from game: Game, playTime: TimeInterval = 0) {
        self.gameId = game.id
        self.actionPoints = game.gameState.actionPoints
        self.currentDay = game.gameState.currentDay
        self.calendar = game.gameState.calendar
        self.houses = game.houses
        self.playerHouseIndex = game.playerHouseIndex
        self.playerMemberIndex = game.playerMemberIndex
        self.player = PlayerStore(from: game.houses[game.playerHouseIndex].members[game.playerMemberIndex])
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
    /// through `gameRepository`.
    public func snapshot() -> Game {
        var updatedHouses = houses
        updatedHouses[playerHouseIndex].members[playerMemberIndex] = player.snapshot()
        return Game(
            id: gameId,
            houses: updatedHouses,
            gameState: GameState(
                currentDay: currentDay,
                actionPoints: actionPoints,
                calendar: calendar
            ),
            playerHouseIndex: playerHouseIndex,
            playerMemberIndex: playerMemberIndex
        )
    }
}

// Duplicated Player data in PlayerStore and in House -> ElfInfo
// think about reimplement house and elf system to avoid duplicated data
