//
//  DefaultRunProgressionMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default `RunProgressionMutator`. Stateless — every method is a pure
/// function of its arguments, mirroring the rules formerly inlined on
/// `DungeonSession`.
public final class DefaultRunProgressionMutator: RunProgressionMutator {

    public init() {}

    // MARK: - RunProgressionMutator

    public func beginRun(
        entryRoomId: DungeonRoomID,
        heroId: ElfID,
        allyIds: [ElfID],
        squadElves: [ElfInfo]
    ) -> RunBeginResult {
        var locations: [ElfID: DungeonRoomID] = [heroId: entryRoomId]
        for allyId in allyIds { locations[allyId] = entryRoomId }

        var vitals: [ElfID: DungeonElfVitals] = [:]
        for elf in squadElves {
            vitals[elf.id] = DungeonElfVitals(hp: Int(elf.maxHP), mp: Int(elf.maxMP))
        }
        return RunBeginResult(elfLocations: locations, roomVitals: vitals)
    }

    public func restoreQuarter(
        squadElves: [ElfInfo],
        roomVitals: [ElfID: DungeonElfVitals]
    ) -> [ElfID: DungeonElfVitals] {
        updateLivingVitals(squadElves: squadElves, roomVitals: roomVitals) { elf, vitals in
            let maxHP = Int(elf.maxHP)
            let maxMP = Int(elf.maxMP)
            vitals.hp = min(maxHP, vitals.hp + maxHP / 4)
            vitals.mp = min(maxMP, vitals.mp + maxMP / 4)
        }
    }

    public func apply(
        _ outcome: DungeonEventOutcome,
        squadElves: [ElfInfo],
        roomVitals: [ElfID: DungeonElfVitals],
        currentRoomId: DungeonRoomID?,
        clearedRoomIds: Set<DungeonRoomID>
    ) -> RunApplyResult {
        var vitals = roomVitals
        switch outcome.restore {
        case .full:
            vitals = updateLivingVitals(squadElves: squadElves, roomVitals: roomVitals) { elf, vitals in
                vitals.hp = Int(elf.maxHP)
                vitals.mp = Int(elf.maxMP)
            }
        case nil:
            break
        }

        var clearedRoomIds = clearedRoomIds
        if outcome.clearsRoom, let currentRoomId {
            clearedRoomIds.insert(currentRoomId)
        }
        return RunApplyResult(roomVitals: vitals, clearedRoomIds: clearedRoomIds)
    }

    public func moveSquadToNextRoom(
        nextRoomId: DungeonRoomID?,
        elfLocations: [ElfID: DungeonRoomID]
    ) -> [ElfID: DungeonRoomID] {
        guard let nextRoomId else { return elfLocations }
        var locations: [ElfID: DungeonRoomID] = [:]
        for id in elfLocations.keys { locations[id] = nextRoomId }
        return locations
    }

    // MARK: - Private

    /// Applies `transform` to each *living* member's vitals (downed members,
    /// `hp <= 0`, are skipped — no revive). Shared by `restoreQuarter` and `apply(_:)`.
    private func updateLivingVitals(
        squadElves: [ElfInfo],
        roomVitals: [ElfID: DungeonElfVitals],
        transform: (ElfInfo, inout DungeonElfVitals) -> Void
    ) -> [ElfID: DungeonElfVitals] {
        var roomVitals = roomVitals
        let byId = Dictionary(squadElves.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for id in Array(roomVitals.keys) {
            guard var vitals = roomVitals[id], vitals.hp > 0, let elf = byId[id] else { continue }
            transform(elf, &vitals)
            roomVitals[id] = vitals
        }
        return roomVitals
    }
}
