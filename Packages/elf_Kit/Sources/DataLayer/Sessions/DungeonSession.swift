//
//  DungeonSession.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Per-run owner of dungeon state. Mirrors `GameSession` for game-wide state:
/// `@MainActor @Observable`, sync mutations on the main thread, observable
/// per-property from SwiftUI views.
///
/// Lifecycle: created by `GameSession.startDungeonSession(...)` when the
/// player taps Dungeon on a Dungeon Day, released by `endDungeonSession()`
/// when they leave the briefing or finish the run. Stable inputs
/// (`dungeonId`, `allyIds`) are joined by the mutating run state: each elf's
/// current room (`elfLocations`). Alive/dead members, defeated rooms, and
/// collected drops land in later phases.
@MainActor
@Observable
public final class DungeonSession {

    // MARK: - Dependencies

    private let dungeonRepository: any DungeonRepository

    /// Read-only access to the parent game-level state (player, houses).
    /// Future phases will add mutator references when dungeon mutations land.
    public let gameStore: GameStore

    // MARK: - Inputs (stable for the lifetime of the run)

    public let dungeonId: DungeonID
    public let allyIds: [ElfID]

    // MARK: - Run state (mutable, main-thread)

    /// Current room of each squad elf. Empty = still in briefing (before
    /// entrance). `onePath`: everyone shares one room; `splitPath`/`randomPath`
    /// will populate them differently.
    public private(set) var elfLocations: [ElfID: DungeonRoomID] = [:]

    // MARK: - Initialization

    public init(gameStore: GameStore, dungeonId: DungeonID, allyIds: [ElfID]) {
        @Dependency(\.dungeonRepository) var dungeonRepository
        self.dungeonRepository = dungeonRepository
        self.gameStore = gameStore
        self.dungeonId = dungeonId
        self.allyIds = allyIds
    }

    // MARK: - Derived (read-only lookups from static JSON)

    public var dungeon: Dungeon? {
        dungeonRepository.getById(id: dungeonId)
    }

    public var backgroundImageName: String {
        dungeon?.backgroundImageName ?? ""
    }

    /// MVP: Entrance is always enabled. The view currently pops back; the
    /// real dungeon-run flow lands in a follow-up phase.
    public var canEnter: Bool { true }

    public var heroId: ElfID { gameStore.player.id }

    /// Room the hero is currently in. `nil` while still in the briefing.
    public var currentRoom: DungeonRoom? {
        guard let roomId = elfLocations[heroId] else { return nil }
        return dungeon?.room(id: roomId)
    }

    /// `true` once the squad has entered the dungeon (room mode), `false`
    /// during the briefing.
    public var isInRun: Bool { currentRoom != nil }

    // MARK: - Run mutations

    /// Places the whole squad into the dungeon's entry room. Called once the
    /// entrance transition overlay completes.
    public func beginRun() {
        guard let entry = dungeon?.entryRoomIds.first else { return }
        var locations: [ElfID: DungeonRoomID] = [heroId: entry]
        for allyId in allyIds { locations[allyId] = entry }
        elfLocations = locations
    }
}
