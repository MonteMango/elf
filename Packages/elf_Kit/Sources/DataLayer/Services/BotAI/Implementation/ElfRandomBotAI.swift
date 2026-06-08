//
//  ElfRandomBotAI.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Dependencies

public final class ElfRandomBotAI: BotAIService {

    private let allBodyParts: [BodyPart] = [.head, .body, .leftHand, .rightHand, .legs]

    public init() {}

    // MARK: - BotAIService

    public func selectAttackPoints(count: Int, using generator: WithRandomNumberGenerator) -> Set<BodyPart> {
        let shuffled = generator { allBodyParts.shuffled(using: &$0) }
        return Set(shuffled.prefix(count))
    }

    public func selectDefensePoints(count: Int, using generator: WithRandomNumberGenerator) -> Set<BodyPart> {
        let shuffled = generator { allBodyParts.shuffled(using: &$0) }
        return Set(shuffled.prefix(count))
    }
}
