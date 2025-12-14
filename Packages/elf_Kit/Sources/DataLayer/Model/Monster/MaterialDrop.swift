//
//  MaterialDrop.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public struct MaterialDrop: Codable, Sendable, Hashable {
    public let id: UUID
    public let chances: [ChanceAmount]

    public init(id: UUID, chances: [ChanceAmount]) {
        self.id = id
        self.chances = chances
    }
}
