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

    // MARK: - Dependencies (snapshotted at init)

    private let battleRoundRunner: any BattleRoundRunner
    private let botAI: any BotAIService                // used by autoFillPoints (AUTO button)
    private let battleLogger: any BattleLogger
    private let debugLogger: any DebugBattleLogger
    private let duelPairingService: any DuelPairingService
    private let monsterRepository: any MonsterRepository
    private let battleResultCalculator: any BattleResultCalculator

    // Optional session context (nil for non-hunt battles like dev BattleSetup flow)
    private let session: GameSession?

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

    public init(battle: Battle, session: GameSession? = nil) {
        precondition(!battle.leftTeam.isEmpty, "Battle.leftTeam must be non-empty")
        precondition(!battle.rightTeam.isEmpty, "Battle.rightTeam must be non-empty")

        @Dependency(\.battleRoundRunner) var battleRoundRunner
        @Dependency(\.botAI) var botAI
        @Dependency(\.battleLogger) var battleLogger
        @Dependency(\.debugBattleLogger) var debugLogger
        @Dependency(\.duelPairingService) var duelPairingService
        @Dependency(\.monsterRepository) var monsterRepository
        @Dependency(\.battleResultCalculator) var battleResultCalculator
        self.battleRoundRunner = battleRoundRunner
        self.botAI = botAI
        self.battleLogger = battleLogger
        self.debugLogger = debugLogger
        self.duelPairingService = duelPairingService
        self.monsterRepository = monsterRepository
        self.battleResultCalculator = battleResultCalculator

        self.battle = battle
        self.session = session
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
        guard !isExecutingRound, currentBattleRound != nil else { return }

        let heroIsPaired = heroDuelPair != nil
        if heroIsPaired {
            guard playerAttackPoints.count == playerSnapshot.attackPoints else { return }
            guard playerDefensePoints.count == playerSnapshot.defensePoints else { return }
        }

        isExecutingRound = true
        defer { isExecutingRound = false }

        await runRound(useHeroSelection: true)

        playerAttackPoints.removeAll()
        playerDefensePoints.removeAll()
    }

    /// Spectator flow: hero is dead, surviving allies fight to completion automatically.
    /// `isExecutingRound` is held for the whole watch session (keeps the WATCH button
    /// disabled), and rounds are paced with a small sleep so HP changes stay visible.
    public func executeWatchUntilEnd() async {
        guard !isHeroAlive, !battleEnded, !isExecutingRound else { return }

        isExecutingRound = true
        defer { isExecutingRound = false }

        while !battleEnded {
            await runRound(useHeroSelection: false)
            if !battleEnded {
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    /// Delegates round mechanics to `BattleRoundRunner`, then applies the
    /// returned `RoundOutcome` to the observable state. Advances the round
    /// (or ends the battle) at the end.
    private func runRound(useHeroSelection: Bool) async {
        guard let round = currentBattleRound else { return }

        let heroSelection: HeroSelection?
        if useHeroSelection, let heroId = playerCombatantId {
            heroSelection = HeroSelection(
                combatantId: heroId,
                attackPoints: playerAttackPoints,
                defensePoints: playerDefensePoints
            )
        } else {
            heroSelection = nil
        }

        let outcome = await battleRoundRunner.runRound(
            leftTeam: leftTeam,
            rightTeam: rightTeam,
            round: round,
            heroSelection: heroSelection
        )

        leftTeam = outcome.updatedLeftTeam
        rightTeam = outcome.updatedRightTeam
        for pairResult in outcome.pairResults where pairResult.isHeroPair {
            emitHeroPairUI(pairResult)
        }

        if outcome.battleOutcome != nil {
            battleEnded = true
        } else {
            currentRoundNumber += 1
            generateNewRoundPairings()
        }
    }

    /// Mirrors a hero pair's PairResult into the observable view state and
    /// emits the corresponding manual + debug logs. Uses the *pre-round*
    /// snapshots from the PairResult so logged HP/stats reflect the start
    /// of the round (the team arrays already hold post-round HP at this point).
    private func emitHeroPairUI(_ pair: PairResult) {
        playerLastRoundResults = pair.result.playerResults
        botLastRoundResults = pair.result.botResults
        botAttackPoints = pair.rightAttack
        botDefensePoints = pair.rightDefense

        debugLogger.logRoundStart(
            roundNumber: currentRoundNumber,
            playerSnapshot: pair.leftSnapshot,
            botSnapshot: pair.rightSnapshot,
            playerAttack: Array(pair.leftAttack),
            playerDefense: Array(pair.leftDefense),
            botAttack: Array(pair.rightAttack),
            botDefense: Array(pair.rightDefense)
        )
        let log = battleLogger.createRoundLog(
            roundNumber: currentRoundNumber,
            playerSnapshot: pair.leftSnapshot,
            botSnapshot: pair.rightSnapshot,
            playerActions: (attack: pair.leftAttack, defense: pair.leftDefense),
            botActions: (attack: pair.rightAttack, defense: pair.rightDefense),
            playerResults: pair.result.playerResults,
            botResults: pair.result.botResults
        )
        roundLog.append(log)
        debugLogger.logRoundEnd(
            roundNumber: currentRoundNumber,
            playerOldHP: pair.leftOldHP,
            playerNewHP: pair.leftNewHP,
            botOldHP: pair.rightOldHP,
            botNewHP: pair.rightNewHP,
            playerResults: pair.result.playerResults,
            botResults: pair.result.botResults
        )
    }

    // MARK: - Actions

    /// Calculates battle result, applies rewards to game state, and saves
    public func finishBattle() async {
        guard battleEnded, !isFinishingBattle else { return }
        isFinishingBattle = true

        let outcome = determineBattleOutcome()
        let monster = getMonsterFromBot()
        let currentExp: Int = session?.state.player.currentExp ?? 0

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
        guard let session = session else { return }

        if result.experienceGained > 0 {
            session.addPlayerExperience(result.experienceGained)
        }

        if let huntRewards = result.huntRewards {
            session.addDropsToPlayerInventory(rewards: huntRewards)
        }

        do {
            try await session.save()
        } catch {
            #if DEBUG
            print("[BattleFightViewModel] Failed to save game: \(error)")
            #endif
        }
    }

    // MARK: - Private Helpers

    private func determineBattleOutcome() -> BattleOutcome {
        // `?? .draw` is a defensive fallback — `finishBattle` only fires when
        // `battleEnded == true`, which means at least one side has wiped.
        detectBattleOutcome(left: leftTeam, right: rightTeam) ?? .draw
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
