//
//  DefaultBotTurnSimulator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Dependencies
import Foundation

/// Default simulator: reuses the same production services the player's hunt
/// flow uses (`CombatantSnapshotBuilder`, `BattleSimulationService`,
/// `HuntService`, `ProgressionService`), so a bot hunt resolves identically to
/// a player hunt — full battle, real rewards on victory.
///
/// The full `BattleResult` (round history) is read only for its `winner` and
/// then dropped: across 79 bots × 5 battles, keeping it would be pure waste.
public final class DefaultBotTurnSimulator: BotTurnSimulator {

    // MARK: - Dependencies (snapshotted at init)

    private let monsterRepository: any MonsterRepository
    private let battleSimulationService: any BattleSimulationService
    private let huntService: any HuntService
    private let progressionService: any ProgressionService
    private let snapshotBuilder: any CombatantSnapshotBuilder

    // MARK: - Constants

    /// Monster pool cap, mirroring the player's hunt flow.
    private let maxMonsterLevel = GameMechanicsConstants.maxHuntMonsterLevel

    // MARK: - Initialization

    public init() {
        @Dependency(\.monsterRepository) var monsterRepository
        @Dependency(\.battleSimulationService) var battleSimulationService
        @Dependency(\.huntService) var huntService
        @Dependency(\.progressionService) var progressionService
        @Dependency(\.snapshotBuilder) var snapshotBuilder
        self.monsterRepository = monsterRepository
        self.battleSimulationService = battleSimulationService
        self.huntService = huntService
        self.progressionService = progressionService
        self.snapshotBuilder = snapshotBuilder
    }

    // MARK: - BotTurnSimulator

    public func simulate(_ plan: BotTurnPlan, elf: ElfInfo, seed: UInt64) async -> BotTurnResult {
        guard !plan.actions.isEmpty else { return emptyResult(slot: plan.slot) }

        let level = progressionService.calculateLevel(currentExp: elf.currentExp)
        let monsterLevel = min(level, maxMonsterLevel)
        let monsters = monsterRepository.getMonsters(world: .upper, level: monsterLevel)
        guard !monsters.isEmpty else { return emptyResult(slot: plan.slot) }

        // Built once and reused: every battle starts the bot at full HP from the
        // same value-type snapshot. These simulations are never rendered, so the
        // battle carries no equipment map (the consumer is the UI fight screen).
        let botSnapshot = snapshotBuilder.buildSnapshot(
            elf: elf,
            level: level,
            globalBuffs: elf.globalBuffs
        )

        var totalExp = 0
        var materials: [MaterialReward] = []
        var weapons: [ElfWeaponItem] = []
        var armor: [ElfDefenseItem] = []
        var battles: [BotBattleSummary] = []

        for (index, action) in plan.actions.enumerated() {
            // Cooperative cancellation: stop fighting if the turn was cancelled
            // (e.g. the player left the screen). Already-fought battles stay in
            // the partial result; the caller decides whether to apply it.
            if Task.isCancelled { break }
            switch action {
            case .hunt:
                // One generator per battle drives both monster choice and combat,
                // so the whole turn is reproducible from `seed`.
                let battleSeed = seed &+ UInt64(index) &* 0x9E3779B97F4A7C15
                let generator = WithRandomNumberGenerator(SeededRandomNumberGenerator(seed: battleSeed))

                guard let monster = generator({ monsters.randomElement(using: &$0) }) else { continue }

                let monsterSnapshot = snapshotBuilder.buildSnapshot(from: monster, globalBuffs: [])
                let battle = Battle(
                    leftTeam: [botSnapshot],
                    rightTeam: [monsterSnapshot]
                )

                let result = await battleSimulationService.runSingleBattle(battle, using: generator)
                let won = result.winner == .left

                var battleExp = 0
                var dropCount = 0
                if won {
                    let rewards = huntService.calculateRewards(for: monster)
                    battleExp = rewards.experience
                    totalExp += rewards.experience
                    materials.append(contentsOf: rewards.materials)
                    if let weapon = rewards.weapon { weapons.append(weapon) }
                    if let armorPiece = rewards.armor { armor.append(armorPiece) }
                    dropCount = rewards.materials.count
                        + (rewards.weapon != nil ? 1 : 0)
                        + (rewards.armor != nil ? 1 : 0)
                }

                battles.append(BotBattleSummary(
                    monsterId: monster.id,
                    monsterTitle: monster.title,
                    won: won,
                    experienceGained: battleExp,
                    dropCount: dropCount
                ))
            }
        }

        return BotTurnResult(
            slot: plan.slot,
            experienceGained: totalExp,
            materials: materials,
            weapons: weapons,
            armor: armor,
            actionPointsSpent: battles.count * BotAction.huntCost,
            battles: battles
        )
    }

    // MARK: - Private Helpers

    private func emptyResult(slot: RosterSlot) -> BotTurnResult {
        BotTurnResult(
            slot: slot,
            experienceGained: 0,
            materials: [],
            weapons: [],
            armor: [],
            actionPointsSpent: 0,
            battles: []
        )
    }
}
