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
