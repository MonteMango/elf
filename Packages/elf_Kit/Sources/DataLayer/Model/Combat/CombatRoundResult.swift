//
//  CombatRoundResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

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

    /// Total EP spent by the player on blocks this round
    public let playerEPSpent: Int

    /// Total EP spent by the bot/monster on blocks this round
    public let botEPSpent: Int

    public init(
        playerResults: [BodyPart: PointStatus],
        botResults: [BodyPart: PointStatus],
        playerDamageTaken: Int,
        botDamageTaken: Int,
        playerEPSpent: Int = 0,
        botEPSpent: Int = 0
    ) {
        self.playerResults = playerResults
        self.botResults = botResults
        self.playerDamageTaken = playerDamageTaken
        self.botDamageTaken = botDamageTaken
        self.playerEPSpent = playerEPSpent
        self.botEPSpent = botEPSpent
    }
}
