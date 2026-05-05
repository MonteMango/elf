//
//  CraftDisplayModels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Craft Category (UI tabs)

public enum CraftCategory: String, CaseIterable, Sendable, Identifiable {
    case weapon
    case armor
    case potions
    case scrolls

    public var id: String { rawValue }

    public var displayTitle: String {
        switch self {
        case .weapon: "weapon"
        case .armor: "armor"
        case .potions: "potions"
        case .scrolls: "scrolls"
        }
    }

    /// Maps to data-layer RecipeCategory (only weapon/armor have data)
    public var recipeCategory: RecipeCategory? {
        switch self {
        case .weapon: .weapon
        case .armor: .armor
        case .potions: nil
        case .scrolls: nil
        }
    }
}

// MARK: - Recipe List Item (left panel)

public struct CraftRecipeDisplay: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let imageName: String
    public let shortInfo: String
    public let ingredients: [CraftIngredientCompactDisplay]

    public init(
        id: UUID,
        title: String,
        imageName: String,
        shortInfo: String,
        ingredients: [CraftIngredientCompactDisplay]
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.shortInfo = shortInfo
        self.ingredients = ingredients
    }
}

// MARK: - Ingredient Badge (compact, for list cells)

public struct CraftIngredientCompactDisplay: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let imageName: String
    public let amount: Int

    public init(id: UUID, imageName: String, amount: Int) {
        self.id = id
        self.imageName = imageName
        self.amount = amount
    }
}

// MARK: - Recipe Detail (right panel)

public struct CraftRecipeDetailDisplay: Equatable, Sendable {
    public let recipeId: UUID
    public let title: String
    public let imageName: String
    public let shortInfo: String
    public let attributes: CraftItemAttributes
    public let ingredients: [CraftIngredientDisplay]
    public let canCraft: Bool
    public let missingIngredients: [MissingIngredient]

    public init(
        recipeId: UUID,
        title: String,
        imageName: String,
        shortInfo: String,
        attributes: CraftItemAttributes,
        ingredients: [CraftIngredientDisplay],
        canCraft: Bool,
        missingIngredients: [MissingIngredient]
    ) {
        self.recipeId = recipeId
        self.title = title
        self.imageName = imageName
        self.shortInfo = shortInfo
        self.attributes = attributes
        self.ingredients = ingredients
        self.canCraft = canCraft
        self.missingIngredients = missingIngredients
    }
}

// MARK: - Craft Item Attributes

public struct CraftItemAttributes: Equatable, Sendable {
    public let epBlockCost: Int
    public let strength: Int
    public let agility: Int
    public let power: Int
    public let instinct: Int
    public let endurance: Int
    public let hitPoints: Int
    public let manaPoints: Int

    public init(
        epBlockCost: Int = 0,
        strength: Int = 0,
        agility: Int = 0,
        power: Int = 0,
        instinct: Int = 0,
        endurance: Int = 0,
        hitPoints: Int = 0,
        manaPoints: Int = 0
    ) {
        self.epBlockCost = epBlockCost
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
        self.endurance = endurance
        self.hitPoints = hitPoints
        self.manaPoints = manaPoints
    }
}

// MARK: - Ingredient Display (full, for detail panel)

public struct CraftIngredientDisplay: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let imageName: String
    public let title: String
    public let required: Int
    public let inBag: Int
    public var isSufficient: Bool { inBag >= required }

    public init(id: UUID, imageName: String, title: String, required: Int, inBag: Int) {
        self.id = id
        self.imageName = imageName
        self.title = title
        self.required = required
        self.inBag = inBag
    }
}
