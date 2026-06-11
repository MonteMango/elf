//
//  MaterialDrop.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public struct MaterialDrop: Codable, Sendable, Hashable {
    public let id: MaterialID
    public let chances: [ChanceAmount]

    public init(id: MaterialID, chances: [ChanceAmount]) {
        self.id = id
        self.chances = chances
    }
}
