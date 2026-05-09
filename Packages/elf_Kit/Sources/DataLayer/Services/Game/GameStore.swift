//
//  GameStore.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import Observation

/// Observable state container for an active game session. Holds session-bound
/// mutable state (action points, calendar, houses) and exposes per-property
/// SwiftUI observation. Houses are kept as `[HouseStore]` (runtime, observable)
/// — the player elf is just a computed accessor into one slot of one house,
/// so there's a single source of truth for every elf at runtime.
///
/// `Game` (value-type) is the on-disk / initial-creation shape; the store
/// lifts it into runtime via `init(from:)` and writes it back via `snapshot()`.
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
    public internal(set) var houses: [HouseStore]
    public internal(set) var playTime: TimeInterval

    /// Live reference to the player elf — the SAME `ElfStore` instance that
    /// lives at `houses[playerHouseIndex].members[playerMemberIndex]`. No
    /// duplication: any mutation through `player.X = Y` is immediately
    /// visible through the houses array, and vice versa.
    public var player: ElfStore {
        houses[playerHouseIndex].members[playerMemberIndex]
    }

    // MARK: - Initialization

    public init(from game: Game, playTime: TimeInterval = 0) {
        self.gameId = game.id
        self.actionPoints = game.gameState.actionPoints
        self.currentDay = game.gameState.currentDay
        self.calendar = game.gameState.calendar
        self.houses = game.houses.map { HouseStore(from: $0) }
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
    /// through `gameRepository`. Houses and elves walk the runtime tree and
    /// extract `.snapshot()` from each.
    public func snapshot() -> Game {
        Game(
            id: gameId,
            houses: houses.map { $0.snapshot() },
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
