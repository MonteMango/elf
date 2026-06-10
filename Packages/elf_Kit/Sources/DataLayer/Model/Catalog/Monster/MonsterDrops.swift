//
//  MonsterDrops.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public struct MonsterDrops: Codable, Sendable, Hashable {
    public let weapons: [ItemDrop]
    public let armor: [ItemDrop]
    public let materials: [MaterialDrop]

    public init(weapons: [ItemDrop], armor: [ItemDrop], materials: [MaterialDrop]) {
        self.weapons = weapons
        self.armor = armor
        self.materials = materials
    }
}
