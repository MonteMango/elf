//
//  BattleDiagnostics.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Per-side EP / block diagnostics aggregated over many battles. Re-walks the
/// per-round `PointStatus` entries because `BattleStatistics` doesn't carry
/// EP info. Used by `MultiBattleViewModel.logBalanceDiagnostics` for live
/// dev runs, and by `BattleSimulationIntegrationTests` for headless sweeps.
public struct BattleDiagnostics: Sendable {

    public enum Side: Sendable {
        case bot1
        case bot2
    }

    public var totalEPSpent: Int = 0
    public var totalBlocksUsed: Int = 0
    public var totalWeakBlocksUsed: Int = 0
    public var totalBlocksDefended: Int = 0
    public var totalAttacksLanded: Int = 0
    /// Battles in which this side fully drained its EP pool at some point
    /// (and therefore picked up the battle-scoped `Exhausted` debuff via
    /// the `DefaultBattleRoundRunner` end-of-round hook).
    public var battlesExhausted: Int = 0
    /// Total raw damage this side actually took to HP across all battles.
    /// Sums per-strike `damageTakenValue` of every status in our results.
    public var totalDamageReceived: Int = 0
    /// Total damage soaked up by this side's `Endurance` stat across all
    /// battles. Sum of `enduranceReduction` components of every status in
    /// our results (irrespective of whether final damage was 0).
    public var totalEnduranceReduction: Int = 0
    public var battlesWithBlockFailure: Int = 0
    public var firstFailRounds: [Int] = []
    public var firstFailPercents: [Double] = []

    public init() {}

    /// Aggregate diagnostics for one side across an array of completed battles.
    /// `maxEP` is the side's starting EP pool — used to detect "this battle
    /// drained the pool" (i.e., the side became `Exhausted`).
    public static func compute(
        from battles: [BattleResult],
        side: Side,
        maxEP: Int
    ) -> BattleDiagnostics {
        var diag = BattleDiagnostics()
        for battle in battles {
            var epSpent = 0
            var blocksUsed = 0
            var weakBlocksUsed = 0
            var blocksDefended = 0
            var attacksLanded = 0
            var damageReceived = 0
            var enduranceReduction = 0
            var firstFailRound: Int?

            for round in battle.roundHistory {
                let myDefensePoints: [BodyPart]
                let opponentAttackPoints: [BodyPart]
                let myResults: [BodyPart: PointStatus]
                switch side {
                case .bot1:
                    myDefensePoints = round.bot1DefensePoints
                    opponentAttackPoints = round.bot2AttackPoints
                    myResults = round.bot1Results
                case .bot2:
                    myDefensePoints = round.bot2DefensePoints
                    opponentAttackPoints = round.bot1AttackPoints
                    myResults = round.bot2Results
                }
                blocksDefended += myDefensePoints.count
                attacksLanded += opponentAttackPoints.count
                let defenseSet = Set(myDefensePoints)

                for (part, status) in myResults {
                    epSpent += status.epSpentValue
                    damageReceived += status.damageTakenValue
                    enduranceReduction += status.enduranceReductionValue
                    if case .blocked = status { blocksUsed += 1 }
                    if case .critHit(_, _, _, _, _, let ep) = status, ep > 0 { blocksUsed += 1 }
                    if case .weakBlocked = status { weakBlocksUsed += 1 }
                    if firstFailRound == nil && isBlockFailure(part: part, status: status, defenseSet: defenseSet) {
                        firstFailRound = round.roundNumber
                    }
                }
            }

            let totalRounds = max(battle.roundHistory.count, 1)
            diag.totalEPSpent += epSpent
            diag.totalBlocksUsed += blocksUsed
            diag.totalWeakBlocksUsed += weakBlocksUsed
            diag.totalBlocksDefended += blocksDefended
            diag.totalAttacksLanded += attacksLanded
            diag.totalDamageReceived += damageReceived
            diag.totalEnduranceReduction += enduranceReduction
            if epSpent >= maxEP && maxEP > 0 {
                diag.battlesExhausted += 1
            }
            if let failRound = firstFailRound {
                diag.battlesWithBlockFailure += 1
                diag.firstFailRounds.append(failRound)
                diag.firstFailPercents.append(Double(failRound) / Double(totalRounds))
            }
        }
        return diag
    }

    // A defended-and-attacked body part whose result spent 0 EP means the block
    // check fell through to the undefended path because currentEP < blockCost.
    // `.nothing` is the "not attacked" sentinel and `.weakBlocked` is the
    // Exhausted-still-blocked path — neither counts as a failure.
    private static func isBlockFailure(part: BodyPart, status: PointStatus, defenseSet: Set<BodyPart>) -> Bool {
        guard defenseSet.contains(part) else { return false }
        switch status {
        case .nothing, .weakBlocked, .blocked:
            return false
        case .hit, .critHit, .dodged:
            return status.epSpentValue == 0
        }
    }
}
