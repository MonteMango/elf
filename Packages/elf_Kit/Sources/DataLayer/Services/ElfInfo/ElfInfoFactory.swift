//
//  ElfInfoFactory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Factory protocol for creating ElfInfo instances
public protocol ElfInfoFactory: Sendable {

    /// Create ElfInfo from PlayerCharacter
    /// - Parameter character: The player character to convert
    /// - Returns: ElfInfo with data from the character
    func create(from character: PlayerCharacter) async -> ElfInfo

    /// Create random AI elf with specified level
    /// - Parameter level: The level for the AI elf (1-12)
    /// - Returns: Randomly generated ElfInfo for AI
    func createRandomAI(level: Int) async -> ElfInfo
}
