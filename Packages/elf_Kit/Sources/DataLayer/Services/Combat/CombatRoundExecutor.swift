//
//  CombatRoundExecutor.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Dependencies

// MARK: - CombatRoundExecutor

/// Service for executing a single combat round
/// Handles combat calculation and damage computation
public protocol CombatRoundExecutor: Sendable {

    /// Execute a combat round between player and bot/monster
    /// - Parameters:
    ///   - playerSnapshot: Player's combat snapshot
    ///   - botSnapshot: Bot/monster's combat snapshot
    ///   - playerAttackPoints: Body parts player is attacking
    ///   - playerDefensePoints: Body parts player is defending
    ///   - botAttackPoints: Body parts bot/monster is attacking
    ///   - botDefensePoints: Body parts bot/monster is defending
    ///   - generator: Per-battle random source, threaded from the battle boundary.
    /// - Returns: Combat round result with damage calculations
    func executeRound(
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerAttackPoints: Set<BodyPart>,
        playerDefensePoints: Set<BodyPart>,
        botAttackPoints: Set<BodyPart>,
        botDefensePoints: Set<BodyPart>,
        using generator: WithRandomNumberGenerator
    ) -> CombatRoundResult
}

public extension CombatRoundExecutor {
    /// Convenience: resolves `\.withRandomNumberGenerator` once and delegates.
    func executeRound(
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerAttackPoints: Set<BodyPart>,
        playerDefensePoints: Set<BodyPart>,
        botAttackPoints: Set<BodyPart>,
        botDefensePoints: Set<BodyPart>
    ) -> CombatRoundResult {
        @Dependency(\.withRandomNumberGenerator) var generator
        return executeRound(
            playerSnapshot: playerSnapshot,
            botSnapshot: botSnapshot,
            playerAttackPoints: playerAttackPoints,
            playerDefensePoints: playerDefensePoints,
            botAttackPoints: botAttackPoints,
            botDefensePoints: botDefensePoints,
            using: generator
        )
    }
}
