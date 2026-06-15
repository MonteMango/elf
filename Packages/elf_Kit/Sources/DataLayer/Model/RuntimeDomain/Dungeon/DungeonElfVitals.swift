//
//  DungeonElfVitals.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Current hit/mana points of one squad elf during a dungeon run. Lives only on
/// `DungeonSession` — `ElfInfo` carries no runtime HP/MP, so these reserves are
/// scoped to the run and discarded when it ends. Endurance is a per-battle
/// resource and is not tracked here (each fight starts with a full EP pool).
public struct DungeonElfVitals: Codable, Equatable, Sendable {
    public var hp: Int
    public var mp: Int

    public init(hp: Int, mp: Int) {
        self.hp = hp
        self.mp = mp
    }
}
