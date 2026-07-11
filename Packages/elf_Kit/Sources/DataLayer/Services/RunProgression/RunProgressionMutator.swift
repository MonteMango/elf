//
//  RunProgressionMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Pure rule family for a dungeon run's room-to-room progression, extracted
/// from `DungeonSession` (T13): entering the dungeon, resting between rooms,
/// applying a special-event outcome, and advancing the squad to the next
/// room. `DungeonSession` stays the single *owner* of run state — it snapshots
/// the current state, delegates to this stateless mutator, and writes the
/// returned slice back.
public protocol RunProgressionMutator: Sendable {

    /// Places the whole squad into `entryRoomId` and seeds full HP/MP reserves.
    func beginRun(
        entryRoomId: DungeonRoomID,
        heroId: ElfID,
        allyIds: [ElfID],
        squadElves: [ElfInfo]
    ) -> RunBeginResult

    /// Restores 25% of max HP/MP to every *living* squad member (downed
    /// members stay down — no revive).
    func restoreQuarter(
        squadElves: [ElfInfo],
        roomVitals: [ElfID: DungeonElfVitals]
    ) -> [ElfID: DungeonElfVitals]

    /// Applies a resolved `SpecialEvent` outcome to the run: restores living
    /// members' vitals (no revive) and/or marks the current room cleared.
    func apply(
        _ outcome: DungeonEventOutcome,
        squadElves: [ElfInfo],
        roomVitals: [ElfID: DungeonElfVitals],
        currentRoomId: DungeonRoomID?,
        clearedRoomIds: Set<DungeonRoomID>
    ) -> RunApplyResult

    /// Moves the whole squad into `nextRoomId`. No-op (returns `elfLocations`
    /// unchanged) when `nextRoomId` is nil (final room).
    func moveSquadToNextRoom(
        nextRoomId: DungeonRoomID?,
        elfLocations: [ElfID: DungeonRoomID]
    ) -> [ElfID: DungeonRoomID]
}

/// Result of `beginRun`: the seeded squad positions and vitals.
public struct RunBeginResult: Sendable, Equatable {
    public let elfLocations: [ElfID: DungeonRoomID]
    public let roomVitals: [ElfID: DungeonElfVitals]

    public init(elfLocations: [ElfID: DungeonRoomID], roomVitals: [ElfID: DungeonElfVitals]) {
        self.elfLocations = elfLocations
        self.roomVitals = roomVitals
    }
}

/// Result of `apply(_:)`: the updated vitals and cleared-room set.
public struct RunApplyResult: Sendable, Equatable {
    public let roomVitals: [ElfID: DungeonElfVitals]
    public let clearedRoomIds: Set<DungeonRoomID>

    public init(roomVitals: [ElfID: DungeonElfVitals], clearedRoomIds: Set<DungeonRoomID>) {
        self.roomVitals = roomVitals
        self.clearedRoomIds = clearedRoomIds
    }
}
