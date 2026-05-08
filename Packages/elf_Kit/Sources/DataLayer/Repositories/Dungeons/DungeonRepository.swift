//
//  DungeonRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol DungeonRepository: Repository<Dungeon> {

    /// Returns a randomly chosen dungeon from the available pool, or nil if empty.
    func randomDungeon() -> Dungeon?
}
