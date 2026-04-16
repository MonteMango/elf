//
//  ElfRandomBotAI.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public final class ElfRandomBotAI: BotAIService {

    private let allBodyParts: [BodyPart] = [.head, .body, .leftHand, .rightHand, .legs]

    public init() {}

    // MARK: - BotAIService

    public func selectAttackPoints(count: Int) -> Set<BodyPart> {
        Set(allBodyParts.shuffled().prefix(count))
    }

    public func selectDefensePoints(count: Int) -> Set<BodyPart> {
        Set(allBodyParts.shuffled().prefix(count))
    }
}
