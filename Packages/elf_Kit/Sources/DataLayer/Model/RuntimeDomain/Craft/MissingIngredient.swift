//
//  MissingIngredient.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct MissingIngredient: Sendable, Equatable {
    public let itemId: UUID
    public let required: Int
    public let available: Int
    public let deficit: Int

    public init(itemId: UUID, required: Int, available: Int) {
        self.itemId = itemId
        self.required = required
        self.available = available
        self.deficit = max(0, required - available)
    }
}
