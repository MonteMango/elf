//
//  MonsterRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public protocol MonsterRepository: Sendable {
    /// Get a monster by its ID
    /// - Parameter id: Monster's unique identifier
    /// - Returns: Monster if found, nil otherwise
    func getMonster(id: UUID) -> Monster?

    /// Get all monsters for a specific world and level
    /// - Parameters:
    ///   - world: The world type (upper, middle, lower)
    ///   - level: The level within the world (1, 2, or 3)
    /// - Returns: Array of monsters for that world/level combination
    func getMonsters(world: WorldType, level: Int) -> [Monster]

}
