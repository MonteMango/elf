//
//  ElfDungeonRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfDungeonRepository: DungeonRepository {

    private let items: [Dungeon]
    private let lookup: [UUID: Dungeon]

    public init(dungeonsData: DungeonsData) {
        self.items = dungeonsData.dungeons
        self.lookup = Dictionary(uniqueKeysWithValues: dungeonsData.dungeons.map { ($0.id, $0) })
    }

    public func getAll() -> [Dungeon] { items }

    public func getById(id: UUID) -> Dungeon? { lookup[id] }

    public func randomDungeon() -> Dungeon? { items.randomElement() }
}
