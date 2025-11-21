//
//  AutoBattleRoundResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Result of a single auto-battle round for history and analysis
///
/// Contains all information about what happened during one round:
/// - Attack and defense selections
/// - Damage dealt to each combatant
/// - HP before and after the round
/// - Body part results (hits, crits, dodges, blocks)
public struct AutoBattleRoundResult: Sendable, Identifiable {

    public let id: UUID

    // MARK: - Round Info

    /// Round number (1-based)
    public let roundNumber: Int

    // MARK: - Bot1 Data

    /// Bot1's attack points selection
    public let bot1AttackPoints: [BodyPart]

    /// Bot1's defense points selection
    public let bot1DefensePoints: [BodyPart]

    /// Bot1's HP at the start of this round
    public let bot1StartHP: Int

    /// Bot1's HP at the end of this round
    public let bot1EndHP: Int

    /// Damage taken by bot1 this round
    public let bot1DamageTaken: Int

    /// Damage dealt by bot1 this round
    public let bot1DamageDealt: Int

    /// Bot1's combat results by body part
    public let bot1Results: [BodyPart: PointStatus]

    // MARK: - Bot2 Data

    /// Bot2's attack points selection
    public let bot2AttackPoints: [BodyPart]

    /// Bot2's defense points selection
    public let bot2DefensePoints: [BodyPart]

    /// Bot2's HP at the start of this round
    public let bot2StartHP: Int

    /// Bot2's HP at the end of this round
    public let bot2EndHP: Int

    /// Damage taken by bot2 this round
    public let bot2DamageTaken: Int

    /// Damage dealt by bot2 this round
    public let bot2DamageDealt: Int

    /// Bot2's combat results by body part
    public let bot2Results: [BodyPart: PointStatus]

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        roundNumber: Int,
        bot1AttackPoints: [BodyPart],
        bot1DefensePoints: [BodyPart],
        bot1StartHP: Int,
        bot1EndHP: Int,
        bot1DamageTaken: Int,
        bot1DamageDealt: Int,
        bot1Results: [BodyPart: PointStatus],
        bot2AttackPoints: [BodyPart],
        bot2DefensePoints: [BodyPart],
        bot2StartHP: Int,
        bot2EndHP: Int,
        bot2DamageTaken: Int,
        bot2DamageDealt: Int,
        bot2Results: [BodyPart: PointStatus]
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.bot1AttackPoints = bot1AttackPoints
        self.bot1DefensePoints = bot1DefensePoints
        self.bot1StartHP = bot1StartHP
        self.bot1EndHP = bot1EndHP
        self.bot1DamageTaken = bot1DamageTaken
        self.bot1DamageDealt = bot1DamageDealt
        self.bot1Results = bot1Results
        self.bot2AttackPoints = bot2AttackPoints
        self.bot2DefensePoints = bot2DefensePoints
        self.bot2StartHP = bot2StartHP
        self.bot2EndHP = bot2EndHP
        self.bot2DamageTaken = bot2DamageTaken
        self.bot2DamageDealt = bot2DamageDealt
        self.bot2Results = bot2Results
    }
}
