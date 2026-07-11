//
//  DefaultDungeonLifecycleMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Default `DungeonLifecycleMutator`. Mirrors the rules formerly inlined on
/// `GameSession`'s Dungeon Session Lifecycle MARK. `rosterProgressionMutator`
/// is resolved lazily inside `flushRewards` (not at init) so constructing this
/// mutator doesn't eagerly pull its live-only deps.
public final class DefaultDungeonLifecycleMutator: DungeonLifecycleMutator {

    // MARK: - Initialization

    public init() {}

    // MARK: - DungeonLifecycleMutator

    public func startDungeonSession(gameStore: GameStore, dungeonId: DungeonID, allyIds: [ElfID]) -> DungeonSession {
        DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: allyIds)
    }

    public func releaseDungeonSession() -> DungeonSession? {
        nil
    }

    public func flushRewards(from dungeonSession: DungeonSession, into gameStore: GameStore) {
        @Dependency(\.rosterProgressionMutator) var rosterProgressionMutator

        let rewards = dungeonSession.pendingRewards
        if rewards.experience > 0 {
            gameStore.player.currentExp = rosterProgressionMutator.addExperience(
                rewards.experience, to: gameStore.player.currentExp
            )
        }
        if !rewards.materials.isEmpty || !rewards.weapons.isEmpty || !rewards.armor.isEmpty {
            gameStore.player.inventory = rosterProgressionMutator.addDrops(
                materials: rewards.materials,
                weapons: rewards.weapons,
                armor: rewards.armor,
                to: gameStore.player.inventory
            )
        }
        dungeonSession.clearPendingRewards()
    }

    public func bankDungeonRewardsOnDeath(dungeonSession: DungeonSession?, into gameStore: GameStore) {
        guard let dungeonSession else { return }
        flushRewards(from: dungeonSession, into: gameStore)
    }

    public func finishDungeonRun(dungeonSession: DungeonSession?, into gameStore: GameStore) -> DungeonSession? {
        guard let dungeonSession else { return nil }
        flushRewards(from: dungeonSession, into: gameStore)
        return releaseDungeonSession()
    }

    public func discardDungeonRun() -> DungeonSession? {
        releaseDungeonSession()
    }
}
