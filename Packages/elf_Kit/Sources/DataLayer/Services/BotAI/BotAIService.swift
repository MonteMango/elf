//
//  BotAIService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public protocol BotAIService: Sendable {
    /// Select attack points for bot based on available attack points amount
    func selectAttackPoints(for hero: ElfHero) -> Set<BodyPart>

    /// Select defense points for bot based on available defense points amount
    func selectDefensePoints(for hero: ElfHero) -> Set<BodyPart>
}
