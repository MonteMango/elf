//
//  CraftViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

@Observable
@MainActor
public final class CraftViewModel {

    // MARK: - Dependencies

    let gameService: any GameService
    let recipeRepository: any RecipeRepository
    let itemsRepository: any ItemsRepository
    let materialRepository: any MaterialRepository
    let craftService: any CraftService
    let inventoryService: any InventoryService

    // MARK: - State

    public var selectedCategory: CraftCategory = .weapon
    public var selectedRecipeId: UUID?
    public var isCrafting: Bool = false

    // MARK: - Callbacks

    public var onClose: () -> Void = {}

    // MARK: - Initialization

    public init(
        gameService: any GameService,
        recipeRepository: any RecipeRepository,
        itemsRepository: any ItemsRepository,
        materialRepository: any MaterialRepository,
        craftService: any CraftService,
        inventoryService: any InventoryService
    ) {
        self.gameService = gameService
        self.recipeRepository = recipeRepository
        self.itemsRepository = itemsRepository
        self.materialRepository = materialRepository
        self.craftService = craftService
        self.inventoryService = inventoryService
    }

    // MARK: - Computed

    private var inventory: ElfInventory {
        gameService.game.player.inventory
    }

    public var filteredRecipes: [CraftRecipeListItem] {
        guard let recipeCategory = selectedCategory.recipeCategory else { return [] }
        let recipes = recipeRepository.getRecipes(for: recipeCategory)
        return recipes.map { buildListItem(from: $0) }
    }

    public var selectedRecipeDetail: CraftRecipeDetail? {
        guard let recipeId = selectedRecipeId,
              let recipe = recipeRepository.getRecipe(id: recipeId) else { return nil }
        return buildDetail(from: recipe)
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
        guard let recipeId = selectedRecipeId,
              let recipe = recipeRepository.getRecipe(id: recipeId),
              craftService.canCraft(recipe: recipe, inventory: inventory) else { return }

        // Validate item exists BEFORE deducting materials
        guard let item = itemsRepository.getHeroItem(recipe.resultItemId) else { return }

        isCrafting = true
        try? await Task.sleep(for: .seconds(2))

        var updatedInventory = craftService.deductMaterials(recipe: recipe, from: inventory)
        updatedInventory = inventoryService.addCraftedItem(item, to: updatedInventory)

        gameService.applyCraftResult(updatedInventory)
        isCrafting = false
    }

    private func buildListItem(from recipe: Recipe) -> CraftRecipeListItem {
        let item = itemsRepository.getHeroItem(recipe.resultItemId)
        let title = item?.title ?? "Unknown"
        let imageName = itemImageName(for: item)
        let shortInfo = buildShortInfo(for: item)
        let badges = recipe.ingredients.map { ingredient in
            let material = materialRepository.getMaterial(id: ingredient.itemId)
            return CraftIngredientBadge(
                id: ingredient.itemId,
                imageName: material?.imageName ?? "questionmark",
                amount: ingredient.amount
            )
        }
        return CraftRecipeListItem(
            id: recipe.id,
            title: title,
            imageName: imageName,
            shortInfo: shortInfo,
            ingredients: badges
        )
    }

    private func buildDetail(from recipe: Recipe) -> CraftRecipeDetail {
        let item = itemsRepository.getHeroItem(recipe.resultItemId)
        let title = item?.title ?? "Unknown"
        let imageName = itemImageName(for: item)
        let shortInfo = buildShortInfo(for: item)
        let attributes = CraftItemAttributes(
            strength: Int(item?.strength ?? 0),
            agility: Int(item?.agility ?? 0),
            power: Int(item?.power ?? 0),
            instinct: Int(item?.instinct ?? 0),
            hitPoints: Int(item?.hitPoints ?? 0),
            manaPoints: Int(item?.manaPoints ?? 0)
        )

        let ingredientDisplays = recipe.ingredients.map { ingredient in
            let material = materialRepository.getMaterial(id: ingredient.itemId)
            let inBag = inventory.materials.first(where: { $0.id == ingredient.itemId })?.quantity ?? 0
            return CraftIngredientDisplay(
                id: ingredient.itemId,
                imageName: material?.imageName ?? "questionmark",
                title: material?.title ?? "Unknown",
                required: ingredient.amount,
                inBag: inBag
            )
        }

        let canCraft = craftService.canCraft(recipe: recipe, inventory: inventory)
        let missing = craftService.getMissingIngredients(recipe: recipe, inventory: inventory)

        return CraftRecipeDetail(
            recipeId: recipe.id,
            title: title,
            imageName: imageName,
            shortInfo: shortInfo,
            attributes: attributes,
            ingredients: ingredientDisplays,
            canCraft: canCraft,
            missingIngredients: missing
        )
    }

    private func buildShortInfo(for item: Item?) -> String {
        switch item {
        case let weapon as WeaponItem:
            let handUse: String = switch weapon.handUse {
            case .primary: "one hand"
            case .secondary: "one hand"
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

    private func itemImageName(for item: Item?) -> String {
        guard let item else { return "item_unknown" }
        return item.id.uuidString.lowercased()
    }
}
