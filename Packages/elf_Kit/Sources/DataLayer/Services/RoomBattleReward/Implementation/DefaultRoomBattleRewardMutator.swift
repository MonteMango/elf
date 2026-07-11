//
//  DefaultRoomBattleRewardMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Default `RoomBattleRewardMutator`. Mirrors the rules formerly inlined on
/// `DungeonSession`. `applyBattleOutcome`/`clearPendingRewards` are pure; only
/// `concludeRoomBattle` needs collaborators, resolved lazily inside that method
/// (not at init) so simply constructing this mutator doesn't eagerly pull its
/// live-only deps — the same rule the original inline code followed.
public final class DefaultRoomBattleRewardMutator: RoomBattleRewardMutator {

    // MARK: - Initialization

    public init() {}

    // MARK: - RoomBattleRewardMutator

    public func applyBattleOutcome(
        finalLeftTeam: [CombatantSnapshot],
        outcome: BattleOutcome,
        currentRoomId: DungeonRoomID?,
        roomVitals: [ElfID: DungeonElfVitals],
        clearedRoomIds: Set<DungeonRoomID>
    ) -> RoomBattleOutcomeResult {
        var roomVitals = roomVitals
        for snapshot in finalLeftTeam {
            guard case .elf(let elfId) = snapshot.source else { continue }
            roomVitals[elfId] = DungeonElfVitals(
                hp: max(0, snapshot.currentHP),
                mp: max(0, snapshot.currentMP)
            )
        }
        var clearedRoomIds = clearedRoomIds
        if outcome == .victory, let currentRoomId {
            clearedRoomIds.insert(currentRoomId)
        }
        return RoomBattleOutcomeResult(roomVitals: roomVitals, clearedRoomIds: clearedRoomIds)
    }

    public func concludeRoomBattle(
        outcome: BattleOutcome,
        room: DungeonRoom?,
        wasAlreadyCleared: Bool,
        pendingRewards: DungeonRunRewards,
        playerCurrentExp: Int
    ) -> RoomBattleConcludeResult {
        // Resolved lazily (not in init) so constructing this mutator doesn't
        // eagerly pull these live-only deps — keeps existing tests/flows clean.
        @Dependency(\.dungeonRewardCalculator) var dungeonRewardCalculator
        @Dependency(\.dropService) var dropService
        @Dependency(\.progressionService) var progressionService

        var pendingRewards = pendingRewards
        let bankedExpBefore = pendingRewards.experience

        // A room win earns its rewards whether or not the hero survived the
        // final blow — if the squad cleared the enemies (`.victory`), the loot
        // is owed. Roll once and reuse the same instances for ledger + overlay
        // (the roll uses RNG, never twice).
        var roomRewards: [HuntRewards] = []
        if outcome == .victory, !wasAlreadyCleared, let room {
            roomRewards = dungeonRewardCalculator.roomRewards(monsters: room.kind.monsters)
            for reward in roomRewards {
                pendingRewards.accrue(reward)
            }
        }

        // Cumulative XP bar: animate from the player's real XP plus everything
        // banked in earlier rooms, up by this room's gain.
        let previousExp = playerCurrentExp + bankedExpBefore
        let roomExperience = pendingRewards.experience - bankedExpBefore
        let transition = progressionService.experienceTransition(
            previousExp: previousExp,
            gained: roomExperience
        )

        let drops = roomRewards.flatMap {
            dropService.convertToDropItems(rewards: $0, didWin: outcome == .victory)
        }

        let manualBattleResult = ManualBattleResult(
            outcome: outcome,
            experienceGained: roomExperience,
            drops: drops,
            // Drops are flushed from the run ledger on exit (not from this
            // result), so leave huntRewards nil to avoid double-application.
            huntRewards: nil,
            transition: transition
        )
        return RoomBattleConcludeResult(pendingRewards: pendingRewards, manualBattleResult: manualBattleResult)
    }

    public func clearPendingRewards() -> DungeonRunRewards {
        .empty
    }
}
