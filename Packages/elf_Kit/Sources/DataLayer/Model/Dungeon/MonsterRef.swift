//
//  MonsterRef.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Reference to a `Monster` from `Monsters.json` plus how many times it appears.
public struct MonsterRef: Codable, Sendable, Equatable, Hashable {
    public let monsterId: UUID
    public let count: Int

    public init(monsterId: UUID, count: Int) {
        self.monsterId = monsterId
        self.count = count
    }
}
