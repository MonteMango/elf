//
//  CraftViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class CraftViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let gameService: any GameService
    private let recipeRepository: any RecipeRepository
    private let itemsRepository: any ItemsRepository
    private let materialRepository: any Repository<Material>
    private let oreRepository: any Repository<Ore>
    private let craftService: any CraftService

    // MARK: - Local UI State

    public var selectedCategory: CraftCategory = .weapon
    public var selectedRecipeId: UUID?
    public var isCrafting: Bool = false

    // MARK: - Callbacks

    public var onClose: () -> Void = {}

    // MARK: - Derived state (computed reactively)

    public var filteredRecipes: [CraftRecipeDisplay] {
        guard let recipeCategory = selectedCategory.recipeCategory else { return [] }
        return recipeRepository.recipes(for: recipeCategory).map { buildListItem(from: $0) }
    }

    public var selectedRecipeDetail: CraftRecipeDetailDisplay? {
        guard let recipeId = selectedRecipeId,
              let recipe = recipeRepository.getById(id: recipeId) else {
            return nil
        }
        return buildDetail(from: recipe)
    }

    private var currentInventory: ElfInventory {
        gameService.player.inventory
    }

    // MARK: - Initialization

    public init(gameService: any GameService) {
        @Dependency(\.recipeRepository) var recipeRepository
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.materialRepository) var materialRepository
        @Dependency(\.oreRepository) var oreRepository
        @Dependency(\.craftService) var craftService
        self.recipeRepository = recipeRepository
        self.itemsRepository = itemsRepository
        self.materialRepository = materialRepository
        self.oreRepository = oreRepository
        self.craftService = craftService

        self.gameService = gameService
    }

    // MARK: - Actions

    public func selectCategory(_ category: CraftCategory) {
        selectedCategory = category
        selectedRecipeId = nil
    }

    public func selectRecipe(_ id: UUID) {
        selectedRecipeId = id
    }

    public func craft() async {
        guard !isCrafting else { return }
        guard let recipeId = selectedRecipeId else { return }

        isCrafting = true
        defer { isCrafting = false }

        guard let recipe = recipeRepository.getById(id: recipeId),
              let item = itemsRepository.getHeroItem(recipe.resultItemId) else { return }

        try? await Task.sleep(for: .seconds(2))

        gameService.craftItem(recipe: recipe, item: item)
    }

    // MARK: - Private builders

    private func buildListItem(from recipe: Recipe) -> CraftRecipeDisplay {
        let item = itemsRepository.getHeroItem(recipe.resultItemId)
        let badges: [CraftIngredientCompactDisplay] = recipe.ingredients.map { ingredient in
            let info = ingredientInfo(for: ingredient)
            return CraftIngredientCompactDisplay(
                id: ingredient.itemId,
                imageName: info.imageName,
                amount: ingredient.amount
            )
        }
        return CraftRecipeDisplay(
            id: recipe.id,
            title: item?.title ?? "Unknown",
            imageName: itemImageName(for: item),
            shortInfo: buildShortInfo(for: item),
            ingredients: badges
        )
    }

    private func buildDetail(from recipe: Recipe) -> CraftRecipeDetailDisplay {
        let item = itemsRepository.getHeroItem(recipe.resultItemId)
        let inventory = currentInventory
        let attributes = CraftItemAttributes(
            epBlockCost: Int((item as? WeaponItem)?.epBlockCost ?? 0),
            strength: Int(item?.strength ?? 0),
            agility: Int(item?.agility ?? 0),
            power: Int(item?.power ?? 0),
            instinct: Int(item?.instinct ?? 0),
            endurance: Int(item?.endurance ?? 0),
            hitPoints: Int(item?.hitPoints ?? 0),
            manaPoints: Int(item?.manaPoints ?? 0)
        )

        let ingredientDisplays: [CraftIngredientDisplay] = recipe.ingredients.map { ingredient in
            let info = ingredientInfo(for: ingredient)
            let inBag = inventory.materials.first(where: { $0.id == ingredient.itemId })?.quantity ?? 0
            return CraftIngredientDisplay(
                id: ingredient.itemId,
                imageName: info.imageName,
                title: info.title,
                required: ingredient.amount,
                inBag: inBag
            )
        }

        return CraftRecipeDetailDisplay(
            recipeId: recipe.id,
            title: item?.title ?? "Unknown",
            imageName: itemImageName(for: item),
            shortInfo: buildShortInfo(for: item),
            attributes: attributes,
            ingredients: ingredientDisplays,
            canCraft: craftService.canCraft(recipe: recipe, inventory: inventory),
            missingIngredients: craftService.getMissingIngredients(recipe: recipe, inventory: inventory)
        )
    }

    private func buildShortInfo(for item: Item?) -> String {
        switch item {
        case let weapon as WeaponItem:
            let handUse: String = switch weapon.handUse {
            case .oneHand: "one hand"
            case .both: "two hands"
            }
            return "Attack: \(weapon.minimumAttackPoint)-\(weapon.maximumAttackPoint), \(handUse)"
        case let defense as DefenseItem:
            return "Defense: \(defense.physicalDefensePoint)"
        case let shield as ShieldItem:
            return "Defense: \(shield.physicalDefensePoint)"
        case let robe as RobeItem:
            return "Mana: \(robe.manaPoints ?? 0)"
        default:
            return ""
        }
    }

    private func ingredientInfo(for ingredient: RecipeIngredient) -> (imageName: String, title: String) {
        switch ingredient.type {
        case .material:
            let material = materialRepository.getById(id: ingredient.itemId)
            return (material?.imageName ?? "item_unknown", material?.title ?? "Unknown")
        case .ore:
            let ore = oreRepository.getById(id: OreID(rawValue: ingredient.itemId))
            return (ore?.imageName ?? "item_unknown", ore?.title ?? "Unknown")
        }
    }

    private func itemImageName(for item: Item?) -> String {
        guard let item else { return "item_unknown" }
        return item.id.uuidString.lowercased()
    }
}
