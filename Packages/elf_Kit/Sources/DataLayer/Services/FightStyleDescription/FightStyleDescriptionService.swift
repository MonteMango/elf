//
//  FightStyleDescriptionService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 26.11.25.
//

import Foundation

/// Service for providing fight style descriptions and information
public protocol FightStyleDescriptionService: Sendable {
    /// Get tactical description for a fight style
    /// - Parameter style: The fight style
    /// - Returns: Description of the fight style tactics
    func getDescription(for style: FightStyle) -> String

    /// Get attribute bonus description for a fight style
    /// - Parameter style: The fight style
    /// - Returns: Description of attribute bonuses
    func getAttributeBonusDescription(for style: FightStyle) -> String
}
