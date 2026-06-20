//
//  DungeonRunSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// On-disk snapshot of an in-progress dungeon run, persisted alongside the game
/// so a player who quits mid-dungeon resumes in the same room with the same
/// squad state. ID-reference only — no catalog payload (dungeon/room/elf are
/// resolved from their repositories on load).
///
/// The rewards ledger (pending XP / drops accrued during the run) lands in a
/// later phase; this type carries only run position + squad vitals for now.
public struct DungeonRunSaveData: Codable, Sendable, Equatable {

    /// The dungeon being run (resolved via `DungeonRepository`).
    public let dungeonId: DungeonID

    /// Squad ally ids (hero is the game's player; not stored here).
    public let allyIds: [ElfID]

    /// Current room of each squad elf.
    public let elfLocations: [ElfID: DungeonRoomID]

    /// Current HP/MP of each squad elf.
    public let roomVitals: [ElfID: DungeonElfVitals]

    /// Rooms the squad has cleared.
    public let clearedRoomIds: [DungeonRoomID]

    /// Rewards accrued so far this run (XP + drops), flushed to the game on exit.
    /// Id-reference DTO of the runtime `DungeonRunRewards` ledger.
    public let pendingRewards: DungeonRunRewardsSaveData

    public init(
        dungeonId: DungeonID,
        allyIds: [ElfID],
        elfLocations: [ElfID: DungeonRoomID],
        roomVitals: [ElfID: DungeonElfVitals],
        clearedRoomIds: [DungeonRoomID],
        pendingRewards: DungeonRunRewardsSaveData
    ) {
        self.dungeonId = dungeonId
        self.allyIds = allyIds
        self.elfLocations = elfLocations
        self.roomVitals = roomVitals
        self.clearedRoomIds = clearedRoomIds
        self.pendingRewards = pendingRewards
    }
}
