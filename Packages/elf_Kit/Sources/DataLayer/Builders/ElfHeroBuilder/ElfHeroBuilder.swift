//
//  ElfHeroBuilder.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import Foundation

public protocol ElfHeroBuilder: Sendable {
    /// Build an ElfHero from configuration data
    /// - Parameters:
    ///   - level: Hero level
    ///   - fightStyleAttributes: Attributes from selected fight style
    ///   - randomLevelAttributes: Random attributes gained from levels
    ///   - selectedItems: Dictionary of selected item UUIDs by type
    /// - Returns: Constructed ElfHero or nil if conversion failed
    func buildElfHero(
        level: Int16,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes,
        selectedItems: [HeroItemType: UUID?]
    ) async -> ElfHero?
}
