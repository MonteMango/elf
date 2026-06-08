//
//  BattleStatisticsAccumulator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

/// Per-side accumulator for combat statistics extracted by
/// `BattleStatisticsParser.parseStatistics`. Bundles the counters that used
/// to be passed as 8 separate `inout` parameters.
///
/// Each call to `parseStatistics` updates **two** accumulators:
/// - `attackerStats` receives offensive counters (`critAttempts`,
///   `critSuccesses`, `critMultipliers`, `critBlockBreaks`, `critsDodged`,
///   `strengthDamage`).
/// - `defenderStats` receives defensive counters (`dodgeAttempts`,
///   `dodgeSuccesses`).
///
/// Callers typically keep one accumulator per combatant and pass `bot1`/`bot2`
/// alternately as attacker/defender between rounds.
public struct BattleStatisticsAccumulator: Sendable {

    // Offensive (filled when this side is the attacker)
    public var critAttempts: Int = 0
    public var critSuccesses: Int = 0
    public var critMultipliers: [Double: Int] = [:]
    public var critBlockBreaks: Int = 0
    public var critsDodged: Int = 0
    public var strengthDamage: Int = 0

    // Defensive (filled when this side is the defender)
    public var dodgeAttempts: Int = 0
    public var dodgeSuccesses: Int = 0

    public init() {}
}
