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

    /// Current HP/MP of each squad elf, seeded full at `beginRun()` and updated
    /// after every room battle via `applyBattleOutcome`. A `hp <= 0` entry marks
    /// a downed member. Empty during the briefing.
    public private(set) var roomVitals: [ElfID: DungeonElfVitals] = [:]

    /// Rooms whose battle the squad has won. Drives the room-action button
    /// (`Fight` → `Next`/`Finish`) and the "Cleared" UI marker.
    public private(set) var clearedRoomIds: Set<DungeonRoomID> = []

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

    /// `true` when the hero's current room has been cleared (its battle won).
    public var isCurrentRoomCleared: Bool {
        guard let room = currentRoom else { return false }
        return clearedRoomIds.contains(room.id)
    }

    /// `true` when the hero is at 0 HP after the most recent battle — the run
    /// is over and the player should be sent back to the Game Day screen.
    public var heroIsDowned: Bool {
        guard let vitals = roomVitals[heroId] else { return false }
        return vitals.hp <= 0
    }

    /// `true` when the current room links to a following room (linear path).
    public var hasNextRoom: Bool {
        currentRoom?.nextRoomIds.first != nil
    }

    /// Hero first, then every ally id that still resolves to a roster `ElfInfo`.
    /// Mirrors the resolution used by the Squad / Overview tabs.
    public func squadElves() -> [ElfInfo] {
        let house = gameStore.houses[gameStore.playerHouseIndex]
        let byId = Dictionary(uniqueKeysWithValues: house.members.map { ($0.id, $0) })
        var elves: [ElfInfo] = [gameStore.player]
        for id in allyIds {
            guard let elf = byId[id] else { continue }
            elves.append(elf)
        }
        return elves
    }

    // MARK: - Run mutations

    /// Places the whole squad into the dungeon's entry room and seeds full
    /// HP/MP reserves. Called once the entrance transition overlay completes.
    public func beginRun() {
        guard let entry = dungeon?.entryRoomIds.first else { return }
        var locations: [ElfID: DungeonRoomID] = [heroId: entry]
        for allyId in allyIds { locations[allyId] = entry }
        elfLocations = locations

        var vitals: [ElfID: DungeonElfVitals] = [:]
        for elf in squadElves() {
            vitals[elf.id] = DungeonElfVitals(hp: Int(elf.maxHP), mp: Int(elf.maxMP))
        }
        roomVitals = vitals
    }

    /// Restores 25% of max HP/MP to every *living* squad member (downed members
    /// stay down — no revive). Used during the room-to-room transition.
    public func restoreQuarter() {
        updateLivingVitals { elf, vitals in
            let maxHP = Int(elf.maxHP)
            let maxMP = Int(elf.maxMP)
            vitals.hp = min(maxHP, vitals.hp + maxHP / 4)
            vitals.mp = min(maxMP, vitals.mp + maxMP / 4)
        }
    }

    /// Applies a resolved `SpecialEvent` outcome to the run. `DungeonSession`
    /// stays the single writer of run state; the *policy* (what each event does)
    /// lives in `SpecialEventResolver`. Restores apply to living members only —
    /// no revive (consistent with `restoreQuarter`).
    public func apply(_ outcome: DungeonEventOutcome) {
        switch outcome.restore {
        case .full:
            updateLivingVitals { elf, vitals in
                vitals.hp = Int(elf.maxHP)
                vitals.mp = Int(elf.maxMP)
            }
        case nil:
            break
        }
        if outcome.clearsRoom, let room = currentRoom {
            clearedRoomIds.insert(room.id)
        }
    }

    /// Applies `transform` to each *living* member's vitals (downed members,
    /// `hp <= 0`, are skipped — no revive). Shared by `restoreQuarter` and
    /// `apply(_:)`.
    private func updateLivingVitals(_ transform: (ElfInfo, inout DungeonElfVitals) -> Void) {
        let byId = Dictionary(squadElves().map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for id in Array(roomVitals.keys) {
            guard var vitals = roomVitals[id], vitals.hp > 0, let elf = byId[id] else { continue }
            transform(elf, &vitals)
            roomVitals[id] = vitals
        }
    }

    /// Moves the whole squad into the current room's first next room (linear
    /// path). No-op on a final room.
    public func moveSquadToNextRoom() {
        guard let next = currentRoom?.nextRoomIds.first else { return }
        var locations: [ElfID: DungeonRoomID] = [:]
        for id in elfLocations.keys { locations[id] = next }
        elfLocations = locations
    }
}

// MARK: - Battle outcome

extension DungeonSession {

    /// Concludes a room battle: folds the final squad state into the run (vitals
    /// + room-clear on hero survival) and returns a result for the overlay.
    ///
    /// Phase 1: no rewards are granted here — dungeon rewards are accrued during
    /// the run and flushed to `GameSession` on exit (later phase), so the result
    /// is outcome-only (0 XP, no drops). Saving is owned by the dungeon flow,
    /// not by the battle layer.
    public func concludeRoomBattle(
        outcome: BattleOutcome,
        finalLeftTeam: [CombatantSnapshot]
    ) -> ManualBattleResult {
        // Resolved lazily (not in init) so constructing a DungeonSession doesn't
        // eagerly pull this live-only dep — keeps existing tests/flows clean.
        @Dependency(\.battleResultCalculator) var battleResultCalculator
        applyBattleOutcome(finalLeftTeam: finalLeftTeam, outcome: outcome)
        return battleResultCalculator.calculateResult(
            outcome: outcome,
            monster: nil,
            currentExp: gameStore.player.currentExp
        )
    }

    /// Folds a finished room battle back into the run: writes each elf's
    /// end-of-battle HP/MP into `roomVitals`, and — if the hero survived —
    /// marks the current room cleared. A downed hero leaves the room uncleared;
    /// the run ends from the Game Day side. Called by `concludeRoomBattle`.
    public func applyBattleOutcome(finalLeftTeam: [CombatantSnapshot], outcome: BattleOutcome) {
        for snapshot in finalLeftTeam {
            guard case .elf(let elfId) = snapshot.source else { continue }
            roomVitals[elfId] = DungeonElfVitals(
                hp: max(0, snapshot.currentHP),
                mp: max(0, snapshot.currentMP)
            )
        }
        if !heroIsDowned, let room = currentRoom {
            clearedRoomIds.insert(room.id)
        }
    }
}
