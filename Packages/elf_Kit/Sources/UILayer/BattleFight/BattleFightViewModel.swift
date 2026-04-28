//
//  BattleFightViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class BattleFightViewModel {

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.botAI) private var botAI

    @ObservationIgnored
    @Dependency(\.combatRoundExecutor) private var combatRoundExecutor

    @ObservationIgnored
    @Dependency(\.battleLogger) private var battleLogger

    @ObservationIgnored
    @Dependency(\.debugBattleLogger) private var debugLogger

    @ObservationIgnored
    @Dependency(\.duelPairingService) private var duelPairingService

    @ObservationIgnored
    @Dependency(\.monsterRepository) private var monsterRepository

    @ObservationIgnored
    @Dependency(\.battleResultCalculator) private var battleResultCalculator

    // Optional session context (nil for non-hunt battles like dev BattleSetup flow)
    private let gameService: (any GameService)?

    // MARK: - State

    public let battle: Battle
    public var battleEnded: Bool = false
    public private(set) var isExecutingRound: Bool = false
    private var isFinishingBattle: Bool = false

    /// Battle result for UI display (set when battle ends)
    public private(set) var battleResult: ManualBattleResult?

    // MARK: - Teams (mutable: currentHP changes per round)

    public private(set) var leftTeam: [CombatantSnapshot]
    public private(set) var rightTeam: [CombatantSnapshot]

    /// Identity of the player-controlled combatant in `leftTeam`. By convention the hero
    /// is `leftTeam[0]`; nil for dev/auto flows that don't have a player.
    public let playerCombatantId: UUID?

    // MARK: - Round State

    /// Round logs accumulated during the battle (hero pair only)
    public private(set) var roundLog: [ManualBattleRoundLog] = []

    /// Current round number, advanced once per FIGHT regardless of hero participation.
    public private(set) var currentRoundNumber: Int = 1

    /// Current battle round with duel pairs (owned by ViewModel, not Battle)
    public private(set) var currentBattleRound: BattleRound?

    // MARK: - Player / Bot view-state (driven by active duel pair)

    public var playerSnapshot: CombatantSnapshot {
        if let id = playerCombatantId,
           let snapshot = leftTeam.first(where: { $0.id == id }) {
            return snapshot
        }
        return leftTeam[0]
    }

    /// The duel pair containing the hero in the current round, if any.
    public var heroDuelPair: DuelPair? {
        guard let id = playerCombatantId else { return nil }
        return currentBattleRound?.duelPairs.first(where: { $0.leftCombatantId == id })
    }

    public var botSnapshot: CombatantSnapshot? {
        guard let opponentId = heroDuelPair?.rightCombatantId,
              let snapshot = rightTeam.first(where: { $0.id == opponentId })
        else { return nil }
        return snapshot
    }

    public var playerCurrentHP: Int { playerSnapshot.currentHP }
    public var playerMaxHP: Int { playerSnapshot.maxHP }
    public var botCurrentHP: Int? { botSnapshot?.currentHP }
    public var botMaxHP: Int? { botSnapshot?.maxHP }

    public var isHeroAlive: Bool { playerSnapshot.isAlive }

    /// Hero is alive but has no opponent in the current round (landed in `waitingLeftIds`).
    public var isHeroWaiting: Bool {
        guard isHeroAlive, currentBattleRound != nil else { return false }
        return heroDuelPair == nil
    }

    /// Last opponent shown next to the hero — kept around for stable UI geometry while the
    /// hero is waiting (no real opponent) or dead. Updated whenever a new real opponent
    /// appears; never reset to nil after the first round.
    public private(set) var displayedBotSnapshot: CombatantSnapshot?

    public var playerAttackPoints: Set<BodyPart> = []
    public var playerDefensePoints: Set<BodyPart> = []

    /// Last bot selections shown for the hero pair (kept for parity with prior UI/logging).
    public var botAttackPoints: Set<BodyPart> = []
    public var botDefensePoints: Set<BodyPart> = []

    // MARK: - Round Results (hero pair only, surfaced in HeroDisplayView)

    public var playerLastRoundResults: [BodyPart: PointStatus] = [:]
    public var botLastRoundResults: [BodyPart: PointStatus] = [:]

    // MARK: - Initialization

    public init(battle: Battle, gameService: (any GameService)? = nil) {
        precondition(!battle.leftTeam.isEmpty, "Battle.leftTeam must be non-empty")
        precondition(!battle.rightTeam.isEmpty, "Battle.rightTeam must be non-empty")
        self.battle = battle
        self.gameService = gameService
        self.leftTeam = battle.leftTeam
        self.rightTeam = battle.rightTeam
        self.playerCombatantId = battle.leftTeam.first?.id
        self.displayedBotSnapshot = battle.rightTeam.first
    }

    // MARK: - Data Loading

    /// Loads initial battle data. Call from View's .task {} modifier.
    public func loadInitialData() {
        generateNewRoundPairings()
    }

    // MARK: - Player Actions

    public func togglePlayerAttackPoint(_ bodyPart: BodyPart) {
        let maxAttackPoints = playerSnapshot.attackPoints

        if playerAttackPoints.contains(bodyPart) {
            playerAttackPoints.remove(bodyPart)
        } else if playerAttackPoints.count < maxAttackPoints {
            playerAttackPoints.insert(bodyPart)
        }
    }

    public func togglePlayerDefensePoint(_ bodyPart: BodyPart) {
        let maxDefensePoints = playerSnapshot.defensePoints

        if playerDefensePoints.contains(bodyPart) {
            playerDefensePoints.remove(bodyPart)
        } else if playerDefensePoints.count < maxDefensePoints {
            playerDefensePoints.insert(bodyPart)
        }
    }

    public func autoFillPoints() {
        playerAttackPoints = botAI.selectAttackPoints(count: playerSnapshot.attackPoints)
        playerDefensePoints = botAI.selectDefensePoints(count: playerSnapshot.defensePoints)
    }

    // MARK: - Round Execution

    public func executeFightRound() async {
        guard !isExecutingRound else { return }
        guard let round = currentBattleRound else { return }

        let heroIsPaired = heroDuelPair != nil
        if heroIsPaired {
            guard playerAttackPoints.count == playerSnapshot.attackPoints else { return }
            guard playerDefensePoints.count == playerSnapshot.defensePoints else { return }
        }

        isExecutingRound = true
        defer { isExecutingRound = false }

        for pair in round.duelPairs {
            guard
                let leftIdx = leftTeam.firstIndex(where: { $0.id == pair.leftCombatantId }),
                let rightIdx = rightTeam.firstIndex(where: { $0.id == pair.rightCombatantId })
            else { continue }

            let left = leftTeam[leftIdx]
            let right = rightTeam[rightIdx]
            let isHeroPair = (left.id == playerCombatantId)

            let leftAttack: Set<BodyPart>
            let leftDefense: Set<BodyPart>
            if isHeroPair {
                leftAttack = playerAttackPoints
                leftDefense = playerDefensePoints
            } else {
                leftAttack = botAI.selectAttackPoints(count: left.attackPoints)
                leftDefense = botAI.selectDefensePoints(count: left.defensePoints)
            }
            let rightAttack = botAI.selectAttackPoints(count: right.attackPoints)
            let rightDefense = botAI.selectDefensePoints(count: right.defensePoints)

            let result = combatRoundExecutor.executeRound(
                playerSnapshot: left,
                botSnapshot: right,
                playerAttackPoints: leftAttack,
                playerDefensePoints: leftDefense,
                botAttackPoints: rightAttack,
                botDefensePoints: rightDefense
            )

            let leftOldHP = left.currentHP
            let rightOldHP = right.currentHP
            leftTeam[leftIdx].currentHP = max(0, leftOldHP - result.playerDamageTaken)
            rightTeam[rightIdx].currentHP = max(0, rightOldHP - result.botDamageTaken)

            if isHeroPair {
                playerLastRoundResults = result.playerResults
                botLastRoundResults = result.botResults
                botAttackPoints = rightAttack
                botDefensePoints = rightDefense

                debugLogger.logRoundStart(
                    roundNumber: currentRoundNumber,
                    playerSnapshot: left,
                    botSnapshot: right,
                    playerAttack: Array(leftAttack),
                    playerDefense: Array(leftDefense),
                    botAttack: Array(rightAttack),
                    botDefense: Array(rightDefense)
                )
                let log = battleLogger.createRoundLog(
                    roundNumber: currentRoundNumber,
                    playerSnapshot: left,
                    botSnapshot: right,
                    playerActions: (attack: leftAttack, defense: leftDefense),
                    botActions: (attack: rightAttack, defense: rightDefense),
                    playerResults: result.playerResults,
                    botResults: result.botResults
                )
                roundLog.append(log)
                debugLogger.logRoundEnd(
                    roundNumber: currentRoundNumber,
                    playerOldHP: leftOldHP,
                    playerNewHP: leftTeam[leftIdx].currentHP,
                    botOldHP: rightOldHP,
                    botNewHP: rightTeam[rightIdx].currentHP,
                    playerResults: result.playerResults,
                    botResults: result.botResults
                )
            }
        }

        playerAttackPoints.removeAll()
        playerDefensePoints.removeAll()

        let leftAlive = leftTeam.contains(where: { $0.isAlive })
        let rightAlive = rightTeam.contains(where: { $0.isAlive })

        if !leftAlive || !rightAlive {
            battleEnded = true
        } else {
            currentRoundNumber += 1
            generateNewRoundPairings()
        }
    }

    /// Spectator flow: hero is dead, surviving allies fight to completion automatically.
    public func executeWatchUntilEnd() async {
        guard !isHeroAlive, !battleEnded, !isExecutingRound else { return }
        while !battleEnded {
            await runAutoRound()
        }
    }

    private func runAutoRound() async {
        guard let round = currentBattleRound else { return }
        isExecutingRound = true
        defer { isExecutingRound = false }

        for pair in round.duelPairs {
            guard
                let leftIdx = leftTeam.firstIndex(where: { $0.id == pair.leftCombatantId }),
                let rightIdx = rightTeam.firstIndex(where: { $0.id == pair.rightCombatantId })
            else { continue }

            let left = leftTeam[leftIdx]
            let right = rightTeam[rightIdx]
            let leftAttack = botAI.selectAttackPoints(count: left.attackPoints)
            let leftDefense = botAI.selectDefensePoints(count: left.defensePoints)
            let rightAttack = botAI.selectAttackPoints(count: right.attackPoints)
            let rightDefense = botAI.selectDefensePoints(count: right.defensePoints)

            let result = combatRoundExecutor.executeRound(
                playerSnapshot: left,
                botSnapshot: right,
                playerAttackPoints: leftAttack,
                playerDefensePoints: leftDefense,
                botAttackPoints: rightAttack,
                botDefensePoints: rightDefense
            )

            leftTeam[leftIdx].currentHP = max(0, left.currentHP - result.playerDamageTaken)
            rightTeam[rightIdx].currentHP = max(0, right.currentHP - result.botDamageTaken)
        }

        let leftAlive = leftTeam.contains(where: { $0.isAlive })
        let rightAlive = rightTeam.contains(where: { $0.isAlive })

        if !leftAlive || !rightAlive {
            battleEnded = true
        } else {
            currentRoundNumber += 1
            generateNewRoundPairings()
        }
    }

    // MARK: - Actions

    /// Calculates battle result, applies rewards to game state, and saves
    public func finishBattle() async {
        guard battleEnded, !isFinishingBattle else { return }
        isFinishingBattle = true

        let outcome = determineBattleOutcome()
        let monster = getMonsterFromBot()
        let currentExp: Int = gameService?.player.currentExp ?? 0

        let result = battleResultCalculator.calculateResult(
            outcome: outcome,
            monster: monster,
            currentExp: currentExp
        )
        battleResult = result

        await applyBattleRewards(result: result, monster: monster)
    }

    /// Applies battle rewards to game state (XP, drops, save)
    private func applyBattleRewards(result: ManualBattleResult, monster: Monster?) async {
        guard let gameService = gameService else { return }

        if result.experienceGained > 0 {
            gameService.addPlayerExperience(result.experienceGained)
        }

        if let huntRewards = result.huntRewards {
            gameService.addDropsToPlayerInventory(rewards: huntRewards)
        }

        do {
            try await gameService.saveGame()
        } catch {
            #if DEBUG
            print("[BattleFightViewModel] Failed to save game: \(error)")
            #endif
        }
    }

    // MARK: - Private Helpers

    private func determineBattleOutcome() -> BattleOutcome {
        let leftAlive = leftTeam.contains(where: { $0.isAlive })
        let rightAlive = rightTeam.contains(where: { $0.isAlive })
        switch (leftAlive, rightAlive) {
        case (true, false): return .victory
        case (false, true): return .defeat
        default:            return .draw
        }
    }

    private func getMonsterFromBot() -> Monster? {
        guard let botSnapshot = rightTeam.first,
              botSnapshot.combatantType == .monster else {
            return nil
        }
        return monsterRepository.getById(id: botSnapshot.sourceId)
    }

    // MARK: - Duel Pairs

    /// Generates new random pairings for the current round
    public func generateNewRoundPairings() {
        currentBattleRound = duelPairingService.createRandomPairs(
            leftTeam: leftTeam,
            rightTeam: rightTeam,
            roundNumber: currentRoundNumber
        )
        if let bot = botSnapshot {
            displayedBotSnapshot = bot
        }
        debugLogger.logRoundState(
            roundNumber: currentRoundNumber,
            leftTeam: leftTeam,
            rightTeam: rightTeam,
            playerCombatantId: playerCombatantId,
            battleRound: currentBattleRound
        )
    }
}
