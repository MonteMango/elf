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
/// when they leave the briefing or finish the run. Phase 1 — only stable
/// inputs (`dungeonId`, `allyIds`); the mutating run state (alive/dead
/// members, current room, defeated rooms, drops collected) lands in Phase 4
/// with `DungeonRoomScreen`.
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
}
