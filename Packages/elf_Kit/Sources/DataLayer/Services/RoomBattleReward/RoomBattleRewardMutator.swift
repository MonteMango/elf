//
//  RoomBattleRewardMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Rule family for folding a resolved room battle back into the run and
/// accruing its rewards, extracted from `DungeonSession` (T14):
/// `applyBattleOutcome`, `concludeRoomBattle`, and `clearPendingRewards`.
/// `DungeonSession` stays the single *owner* of run state — it snapshots the
/// current state, delegates to this mutator, and writes the returned slice
/// back.
public protocol RoomBattleRewardMutator: Sendable {

    /// Folds a finished room battle's final squad state into the run: each
    /// elf's end-of-battle HP/MP, and — on a squad win (`.victory`) — the
    /// current room marked cleared.
    func applyBattleOutcome(
        finalLeftTeam: [CombatantSnapshot],
        outcome: BattleOutcome,
        currentRoomId: DungeonRoomID?,
        roomVitals: [ElfID: DungeonElfVitals],
        clearedRoomIds: Set<DungeonRoomID>
    ) -> RoomBattleOutcomeResult

    /// Accrues the current room's rewards into the run ledger (once, on its
    /// first clear) and builds the overlay's `ManualBattleResult`. `room` and
    /// `wasAlreadyCleared` are captured by the caller *before* this battle's
    /// mutation, so a room's rewards are rolled and accrued exactly once.
    func concludeRoomBattle(
        outcome: BattleOutcome,
        room: DungeonRoom?,
        wasAlreadyCleared: Bool,
        pendingRewards: DungeonRunRewards,
        playerCurrentExp: Int
    ) -> RoomBattleConcludeResult

    /// Empties the run reward ledger after it has been flushed into the player.
    func clearPendingRewards() -> DungeonRunRewards
}

/// Result of `applyBattleOutcome`: the updated vitals and cleared-room set.
public struct RoomBattleOutcomeResult: Sendable, Equatable {
    public let roomVitals: [ElfID: DungeonElfVitals]
    public let clearedRoomIds: Set<DungeonRoomID>

    public init(roomVitals: [ElfID: DungeonElfVitals], clearedRoomIds: Set<DungeonRoomID>) {
        self.roomVitals = roomVitals
        self.clearedRoomIds = clearedRoomIds
    }
}

/// Result of `concludeRoomBattle`: the updated ledger and the overlay result.
public struct RoomBattleConcludeResult: Sendable, Equatable {
    public let pendingRewards: DungeonRunRewards
    public let manualBattleResult: ManualBattleResult

    public init(pendingRewards: DungeonRunRewards, manualBattleResult: ManualBattleResult) {
        self.pendingRewards = pendingRewards
        self.manualBattleResult = manualBattleResult
    }
}
