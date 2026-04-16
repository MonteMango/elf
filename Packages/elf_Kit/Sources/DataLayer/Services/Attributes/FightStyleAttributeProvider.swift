//
//  FightStyleAttributeProvider.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Provides attributes based on fight style
public protocol FightStyleAttributeProvider: Sendable {

    /// Get all attributes for a specific fight style at a given level
    ///
    /// - Parameters:
    ///   - fightStyle: The hero's fighting style
    ///   - level: The hero's level
    /// - Returns: Calculated attributes for the fight style
    func getAllFightStyleAttributes(for fightStyle: FightStyle, at level: Int16) -> HeroAttributes
}
