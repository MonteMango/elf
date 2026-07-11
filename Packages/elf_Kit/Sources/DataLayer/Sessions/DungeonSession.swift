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
/// player taps Dungeon on a Dungeon Day, released by `finishDungeonRun()`
/// (with reward flush) or `discardDungeonRun()` (no rewards) when they leave
/// the run. Stable inputs
/// (`dungeonId`, `allyIds`) are joined by the mutating run state: each elf's
/// current room (`elfLocations`). Alive/dead members, defeated rooms, and
/// collected drops land in later phases.
@MainActor
@Observable
public final class DungeonSession {

    // MARK: - Dependencies

    private let dungeonRepository: any DungeonRepository
    private let runProgressionMutator: any RunProgressionMutator
    private let roomBattleRewardMutator: any RoomBattleRewardMutator

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

    /// XP + drops earned across the run, accrued per cleared room and flushed to
    /// the game on exit (Finish *or* hero death). Held only in memory between
    /// rooms; `makeSaveData()` persists it so a resumed run keeps its ledger.
    public private(set) var pendingRewards: DungeonRunRewards = .empty

    // MARK: - Initialization

    public init(gameStore: GameStore, dungeonId: DungeonID, allyIds: [ElfID]) {
        @Dependency(\.dungeonRepository) var dungeonRepository
        @Dependency(\.runProgressionMutator) var runProgressionMutator
        @Dependency(\.roomBattleRewardMutator) var roomBattleRewardMutator
        self.dungeonRepository = dungeonRepository
        self.runProgressionMutator = runProgressionMutator
        self.roomBattleRewardMutator = roomBattleRewardMutator
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

    /// Vitals to display for a squad member. During the briefing (`roomVitals`
    /// empty, before `beginRun()`) every member reads full HP/MP; once the squad
    /// has entered, the live per-room values are returned. Single home of the
    /// "full before the run" rule shared by the Overview and Squad tabs.
    public func displayVitals(for elf: ElfInfo) -> DungeonElfVitals {
        roomVitals[elf.id] ?? DungeonElfVitals(hp: Int(elf.maxHP), mp: Int(elf.maxMP))
    }

    // MARK: - Run mutations

    /// Places the whole squad into the dungeon's entry room and seeds full
    /// HP/MP reserves. Called once the entrance transition overlay completes.
    public func beginRun() {
        guard let entry = dungeon?.entryRoomIds.first else { return }
        let result = runProgressionMutator.beginRun(
            entryRoomId: entry,
            heroId: heroId,
            allyIds: allyIds,
            squadElves: squadElves()
        )
        (elfLocations, roomVitals) = (result.elfLocations, result.roomVitals)
    }

    /// Restores 25% of max HP/MP to every *living* squad member (downed members
    /// stay down — no revive). Used during the room-to-room transition.
    public func restoreQuarter() {
        roomVitals = runProgressionMutator.restoreQuarter(squadElves: squadElves(), roomVitals: roomVitals)
    }

    /// Applies a resolved `SpecialEvent` outcome to the run. `DungeonSession`
    /// stays the single writer of run state; the *policy* (what each event does)
    /// lives in `SpecialEventResolver`. Restores apply to living members only —
    /// no revive (consistent with `restoreQuarter`).
    public func apply(_ outcome: DungeonEventOutcome) {
        let result = runProgressionMutator.apply(
            outcome,
            squadElves: squadElves(),
            roomVitals: roomVitals,
            currentRoomId: currentRoom?.id,
            clearedRoomIds: clearedRoomIds
        )
        (roomVitals, clearedRoomIds) = (result.roomVitals, result.clearedRoomIds)
    }

    // MARK: - Persistence

    /// Snapshot of the run for saving. ID-reference only. `clearedRoomIds` is
    /// sorted for deterministic output (the underlying `Set` has no stable order).
    public func makeSaveData() -> DungeonRunSaveData {
        DungeonRunSaveData(
            dungeonId: dungeonId,
            allyIds: allyIds,
            elfLocations: elfLocations,
            roomVitals: roomVitals,
            clearedRoomIds: clearedRoomIds.sorted { $0.rawValue.uuidString < $1.rawValue.uuidString },
            pendingRewards: DungeonRunRewardsSaveData(from: pendingRewards)
        )
    }

    /// Snapshot for persistence, but only when the run is actually **resumable**:
    /// the squad has entered a room and the hero is alive. Returns nil during the
    /// briefing (not yet entered) or when the hero is downed (the run is ending →
    /// Game Day), so a background save in those states doesn't persist a run that
    /// would resume into a broken state.
    public func resumableSaveData() -> DungeonRunSaveData? {
        guard isInRun, !heroIsDowned else { return nil }
        return makeSaveData()
    }

    /// Whether the restored run still resolves against the current catalog: the
    /// dungeon and the hero's room exist, and every cleared room id still exists.
    /// If false, the caller discards the run and resumes on the Game Day screen
    /// (the state before entering the dungeon).
    public func isResumeStateValid() -> Bool {
        guard let dungeon, currentRoom != nil else { return false }
        return clearedRoomIds.allSatisfy { dungeon.room(id: $0) != nil }
    }

    /// Restores mutable run state from a saved snapshot. The stable inputs
    /// (`dungeonId`, `allyIds`) are passed to `init` by the caller; this fills in
    /// the run position + vitals + cleared rooms.
    public func restore(from data: DungeonRunSaveData) {
        assert(
            data.dungeonId == dungeonId && data.allyIds == allyIds,
            "restore(from:) must be called on a session created with the same dungeonId/allyIds"
        )
        elfLocations = data.elfLocations
        roomVitals = data.roomVitals
        clearedRoomIds = Set(data.clearedRoomIds)
        pendingRewards = restoredRewards(from: data.pendingRewards)
    }

    /// Rebuilds the runtime ledger from its on-disk DTO, resolving weapon/armor
    /// ids via the catalog. The `ItemsRepository` is resolved only when there are
    /// weapon/armor drops to resolve — XP/material-only runs (and the tests that
    /// drive them) stay dependency-free.
    private func restoredRewards(from data: DungeonRunRewardsSaveData) -> DungeonRunRewards {
        guard !data.weapons.isEmpty || !data.armor.isEmpty else {
            return DungeonRunRewards(
                experience: data.experience,
                materials: data.materials,
                weapons: [],
                armor: []
            )
        }
        @Dependency(\.itemsRepository) var itemsRepository
        return data.toRewards(using: itemsRepository)
    }

    // MARK: - Run mutations (cont.)

    /// Moves the whole squad into the current room's first next room (linear
    /// path). No-op on a final room.
    public func moveSquadToNextRoom() {
        elfLocations = runProgressionMutator.moveSquadToNextRoom(
            nextRoomId: currentRoom?.nextRoomIds.first,
            elfLocations: elfLocations
        )
    }
}

// MARK: - Battle outcome

extension DungeonSession {

    /// Concludes a room battle: folds the final squad state into the run (vitals
    /// + room-clear on hero survival), accrues the room's rewards into the run
    /// ledger, and returns a result for the overlay.
    ///
    /// Rewards are *not* applied to the game here — they accumulate on the run
    /// and are flushed to `GameSession` on exit (Finish or hero death). The
    /// overlay therefore shows the room's gain over a *cumulative* XP bar: it
    /// animates from the player's real XP plus everything banked in earlier
    /// rooms, to that same total plus this room's XP. Saving is owned by the
    /// dungeon flow, not the battle layer.
    public func concludeRoomBattle(
        outcome: BattleOutcome,
        finalLeftTeam: [CombatantSnapshot]
    ) -> ManualBattleResult {
        // Capture before applyBattleOutcome mutates clearedRoomIds, so the
        // mutator accrues a room's rewards exactly once (only on its first
        // clear).
        let roomBeforeClear = currentRoom
        let wasAlreadyCleared = isCurrentRoomCleared

        applyBattleOutcome(finalLeftTeam: finalLeftTeam, outcome: outcome)

        // A room win earns its rewards whether or not the hero survived the final
        // blow — if the squad cleared the enemies (`.victory`), the loot is owed.
        // A downed hero still ends the run (from the result screen), but the
        // rewards are banked and flushed on the way out.
        let result = roomBattleRewardMutator.concludeRoomBattle(
            outcome: outcome,
            room: roomBeforeClear,
            wasAlreadyCleared: wasAlreadyCleared,
            pendingRewards: pendingRewards,
            playerCurrentExp: gameStore.player.currentExp
        )
        pendingRewards = result.pendingRewards
        return result.manualBattleResult
    }

    /// Folds a finished room battle back into the run: writes each elf's
    /// end-of-battle HP/MP into `roomVitals`, and — on a squad win (`.victory`) —
    /// marks the current room cleared, even if the hero fell on the final blow
    /// (the room is genuinely cleared; the run still ends from the Game Day side).
    /// A defeat/draw leaves the room uncleared. Called by `concludeRoomBattle`.
    public func applyBattleOutcome(finalLeftTeam: [CombatantSnapshot], outcome: BattleOutcome) {
        let result = roomBattleRewardMutator.applyBattleOutcome(
            finalLeftTeam: finalLeftTeam,
            outcome: outcome,
            currentRoomId: currentRoom?.id,
            roomVitals: roomVitals,
            clearedRoomIds: clearedRoomIds
        )
        (roomVitals, clearedRoomIds) = (result.roomVitals, result.clearedRoomIds)
    }

    /// Empties the run reward ledger after it has been flushed into the player.
    /// Keeps the flush idempotent: a second flush (e.g. `finishDungeonRun` after a
    /// death-time bank) then grants nothing.
    public func clearPendingRewards() {
        pendingRewards = roomBattleRewardMutator.clearPendingRewards()
    }
}
