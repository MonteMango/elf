//
//  BattleStatisticsParser.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

/// Service for parsing combat results into per-side battle statistics.
///
/// Extracts crit, dodge, and strength-damage counters from `PointStatus`
/// results. Used by `AutoBattleViewModel` and `ElfBattleSimulationService`.
public protocol BattleStatisticsParser: Sendable {

    /// Parses one combat round, updating both sides' accumulators.
    ///
    /// - Parameters:
    ///   - attackingPoints: body parts the attacker targets this round
    ///   - defendingPoints: body parts the defender blocked this round
    ///   - results: per-body-part outcome from the calculator
    ///   - attackerStats: accumulates offensive counters (crit*, strength damage)
    ///   - defenderStats: accumulates defensive counters (dodge*)
    /// - Returns: the attacker's strength damage **for this round only** (the
    ///   delta added to `attackerStats.strengthDamage` by this call), so
    ///   callers can record per-round strength damage without snapshotting
    ///   the cumulative accumulator around the call.
    @discardableResult
    func parseStatistics(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        results: [BodyPart: PointStatus],
        attackerStats: inout BattleStatisticsAccumulator,
        defenderStats: inout BattleStatisticsAccumulator
    ) -> Int
}
