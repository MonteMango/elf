//
//  ElfMonsterRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public final class ElfMonsterRepository: MonsterRepository {

    // MARK: - Properties

    private let _monstersData: MonstersData
    private let monsterLookup: [UUID: Monster]

    // MARK: - Initialization

    public init(dataLoader: DataLoader = ElfDataLoader()) {
        // Load data synchronously from bundle
        let data: Data
        do {
            data = try dataLoader.loadMonstersData()
        } catch {
            print("⚠️ Warning: Could not load Monsters.json, using empty data: \(error)")
            data = Self.createEmptyMonstersJSON()
        }

        // Decode JSON
        let monstersData: MonstersData
        do {
            monstersData = try JSONDecoder().decode(MonstersData.self, from: data)
        } catch {
            print("⚠️ Warning: Failed to decode monsters, using empty fallback: \(error)")
            monstersData = MonstersData.empty()
        }

        self._monstersData = monstersData

        // Build lookup cache
        var lookup: [UUID: Monster] = [:]

        func index(_ monsters: [Monster]) {
            monsters.forEach { lookup[$0.id] = $0 }
        }

        // Index all monsters from all worlds and levels
        index(monstersData.upperWorld.level1)
        index(monstersData.upperWorld.level2)
        index(monstersData.upperWorld.level3)

        index(monstersData.middleWorld.level1)
        index(monstersData.middleWorld.level2)
        index(monstersData.middleWorld.level3)

        index(monstersData.lowerWorld.level1)
        index(monstersData.lowerWorld.level2)
        index(monstersData.lowerWorld.level3)

        self.monsterLookup = lookup
    }

    // MARK: - MonsterRepository

    public func getMonster(id: UUID) -> Monster? {
        return monsterLookup[id]
    }

    public func getMonsters(world: WorldType, level: Int) -> [Monster] {
        let worldLevels: WorldLevels
        switch world {
        case .upper:
            worldLevels = _monstersData.upperWorld
        case .middle:
            worldLevels = _monstersData.middleWorld
        case .lower:
            worldLevels = _monstersData.lowerWorld
        }

        return worldLevels.monsters(for: level)
    }

    // MARK: - Private Helpers

    private static func createEmptyMonstersJSON() -> Data {
        let emptyJSON = """
        {
            "version": "1.0-empty",
            "upperWorld": {
                "level1": [],
                "level2": [],
                "level3": []
            },
            "middleWorld": {
                "level1": [],
                "level2": [],
                "level3": []
            },
            "lowerWorld": {
                "level1": [],
                "level2": [],
                "level3": []
            }
        }
        """
        return Data(emptyJSON.utf8)
    }
}

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// `_monstersData` is a value type, `monsterLookup` is an immutable dictionary of value types.
extension ElfMonsterRepository: @unchecked Sendable {}
