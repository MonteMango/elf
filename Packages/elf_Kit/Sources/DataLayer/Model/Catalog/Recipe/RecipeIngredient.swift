//
//  RecipeIngredient.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct RecipeIngredient: Decodable, Sendable {
    public let itemId: UUID
    public let type: IngredientType
    public let amount: Int

    public init(itemId: UUID, type: IngredientType, amount: Int) {
        self.itemId = itemId
        self.type = type
        self.amount = amount
    }
}
