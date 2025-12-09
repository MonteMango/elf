//
//  MonsterRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public protocol MonsterRepository: Sendable {
    /// All loaded monsters data
    var monstersData: MonstersData { get }

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

    /// Get a random monster for a specific world and level
    /// - Parameters:
    ///   - world: The world type (upper, middle, lower)
    ///   - level: The level within the world (1, 2, or 3)
    /// - Returns: A random monster if available, nil if no monsters exist for that combination
    func getRandomMonster(world: WorldType, level: Int) -> Monster?
}
