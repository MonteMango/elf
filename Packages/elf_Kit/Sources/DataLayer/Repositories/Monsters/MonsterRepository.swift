//
//  MonsterRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol MonsterRepository: Repository<Monster> {

    /// Get all monsters for a specific world and level.
    func getMonsters(world: WorldType, level: Int) -> [Monster]
}
