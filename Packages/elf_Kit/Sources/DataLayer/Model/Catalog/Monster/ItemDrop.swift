//
//  ItemDrop.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public struct ItemDrop: Codable, Sendable, Hashable {
    public let id: String
    public let chance: Double

    public init(id: String, chance: Double) {
        self.id = id
        self.chance = chance
    }
}
