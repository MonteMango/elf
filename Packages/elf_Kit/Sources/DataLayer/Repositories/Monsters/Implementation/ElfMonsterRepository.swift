//
//  ElfMonsterRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfMonsterRepository: MonsterRepository {

    private let monstersData: MonstersData
    private let items: [Monster]
    private let lookup: [UUID: Monster]

    public init(monstersData: MonstersData) {
        self.monstersData = monstersData

        var items: [Monster] = []
        var lookup: [UUID: Monster] = [:]

        func index(_ monsters: [Monster]) {
            for monster in monsters {
                lookup[monster.id] = monster
            }
            items.append(contentsOf: monsters)
        }

        index(monstersData.upperWorld.level1)
        index(monstersData.upperWorld.level2)
        index(monstersData.upperWorld.level3)
        index(monstersData.middleWorld.level1)
        index(monstersData.middleWorld.level2)
        index(monstersData.middleWorld.level3)
        index(monstersData.lowerWorld.level1)
        index(monstersData.lowerWorld.level2)
        index(monstersData.lowerWorld.level3)

        self.items = items
        self.lookup = lookup
    }

    public func getAll() -> [Monster] { items }

    public func getById(id: UUID) -> Monster? { lookup[id] }

    public func getMonsters(world: WorldType, level: Int) -> [Monster] {
        let worldLevels: WorldLevels
        switch world {
        case .upper: worldLevels = monstersData.upperWorld
        case .middle: worldLevels = monstersData.middleWorld
        case .lower: worldLevels = monstersData.lowerWorld
        }

        return worldLevels.monsters(for: level)
    }
}
