//
//  RandomAttributeGenerator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Generates random attributes for hero leveling
public protocol RandomAttributeGenerator: Sendable {

    /// Generate random attributes for a single level up
    ///
    /// - Returns: Randomly generated attributes
    func getRandomLevelAttributes() -> HeroAttributes

    /// Generate accumulated random attributes for all levels up to the specified level
    ///
    /// - Parameter level: The target level
    /// - Returns: Total accumulated random attributes
    func getAllRandomLevelAttributes(for level: Int16) -> HeroAttributes
}
