//
//  CombatRoundExecutor.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

// MARK: - CombatRoundResult

/// Result of a single combat round execution
public struct CombatRoundResult: Sendable {
    /// Combat results for the player (damage taken per body part)
    public let playerResults: [BodyPart: PointStatus]

    /// Combat results for the bot/monster (damage taken per body part)
    public let botResults: [BodyPart: PointStatus]

    /// Total damage dealt to player this round
    public let playerDamageTaken: Int

    /// Total damage dealt to bot/monster this round
    public let botDamageTaken: Int

    public init(
        playerResults: [BodyPart: PointStatus],
        botResults: [BodyPart: PointStatus],
        playerDamageTaken: Int,
        botDamageTaken: Int
    ) {
        self.playerResults = playerResults
        self.botResults = botResults
        self.playerDamageTaken = playerDamageTaken
        self.botDamageTaken = botDamageTaken
    }
}

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
    /// - Returns: Combat round result with damage calculations
    func executeRound(
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerAttackPoints: Set<BodyPart>,
        playerDefensePoints: Set<BodyPart>,
        botAttackPoints: Set<BodyPart>,
        botDefensePoints: Set<BodyPart>
    ) async -> CombatRoundResult
}
