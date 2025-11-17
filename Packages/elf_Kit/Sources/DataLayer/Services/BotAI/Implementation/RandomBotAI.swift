//
//  RandomBotAI.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public final class RandomBotAI: BotAIService {

    public init() {}

    public func selectAttackPoints(for hero: ElfHero) -> Set<BodyPart> {
        let allBodyParts: [BodyPart] = [.head, .body, .leftHand, .rightHand, .legs]
        let maxPoints = hero.atackPointsAmount
        return Set(allBodyParts.shuffled().prefix(maxPoints))
    }

    public func selectDefensePoints(for hero: ElfHero) -> Set<BodyPart> {
        let allBodyParts: [BodyPart] = [.head, .body, .leftHand, .rightHand, .legs]
        let maxPoints = hero.defensePointsAmount
        return Set(allBodyParts.shuffled().prefix(maxPoints))
    }
}

// MARK: - Sendable Conformance
extension RandomBotAI: @unchecked Sendable {}
