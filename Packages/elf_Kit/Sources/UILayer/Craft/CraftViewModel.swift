//
//  CraftViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

@MainActor
@Observable
public final class CraftViewModel {

    // MARK: - Dependencies

    let gameService: any GameService
    let recipeRepository: any RecipeRepository
    let itemsRepository: any ItemsRepository
    let materialRepository: any Repository<Material>
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
        materialRepository: any Repository<Material>,
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

    // MARK: - Cached State

    public var filteredRecipes: [CraftRecipeListItem] = []
    public var selectedRecipeDetail: CraftRecipeDetail?

    private func currentInventory() async -> ElfInventory {
        (await gameService.game).player.inventory
    }

    // MARK: - Data Loading

    /// Refreshes the filtered recipes list. Called from View's .task(id:) modifier.
    public func refreshRecipes() async {
        guard let recipeCategory = selectedCategory.recipeCategory else {
            filteredRecipes = []
            return
        }
        let recipes = await recipeRepository.recipes(for: recipeCategory)
        var items: [CraftRecipeListItem] = []
        for recipe in recipes {
            guard !Task.isCancelled else { return }
            items.append(await buildListItem(from: recipe))
        }
        guard !Task.isCancelled else { return }
        filteredRecipes = items
    }

    /// Refreshes the selected recipe detail.
    public func refreshSelectedDetail() async {
        guard let recipeId = selectedRecipeId,
              let recipe = await recipeRepository.getById(id: recipeId) else {
            selectedRecipeDetail = nil
            return
        }
        selectedRecipeDetail = await buildDetail(from: recipe)
    }

    // MARK: - Actions

    public func selectCategory(_ category: CraftCategory) {
        selectedCategory = category
        selectedRecipeId = nil
        selectedRecipeDetail = nil
    }

    public func selectRecipe(_ id: UUID) {
        selectedRecipeId = id
    }

    public func craft() async {
        guard !isCrafting else { return }
        guard let recipeId = selectedRecipeId else { return }

        isCrafting = true
        defer { isCrafting = false }

        guard let recipe = await recipeRepository.getById(id: recipeId),
              let item = await itemsRepository.getHeroItem(recipe.resultItemId) else { return }

        try? await Task.sleep(for: .seconds(2))

        // Atomic: validate + deduct + add inside actor
        await gameService.modifyPlayer { [craftService, inventoryService] player in
            guard craftService.canCraft(recipe: recipe, inventory: player.inventory) else { return }
            var updatedInventory = craftService.deductMaterials(recipe: recipe, from: player.inventory)
            updatedInventory = inventoryService.addCraftedItem(item, to: updatedInventory)
            player.inventory = updatedInventory
        }
    }

    private func buildListItem(from recipe: Recipe) async -> CraftRecipeListItem {
        let item = await itemsRepository.getHeroItem(recipe.resultItemId)
        let title = item?.title ?? "Unknown"
        let imageName = itemImageName(for: item)
        let shortInfo = buildShortInfo(for: item)
        var badges: [CraftIngredientBadge] = []
        for ingredient in recipe.ingredients {
            let material = await materialRepository.getById(id: ingredient.itemId)
            badges.append(CraftIngredientBadge(
                id: ingredient.itemId,
                imageName: material?.imageName ?? "questionmark",
                amount: ingredient.amount
            ))
        }
        return CraftRecipeListItem(
            id: recipe.id,
            title: title,
            imageName: imageName,
            shortInfo: shortInfo,
            ingredients: badges
        )
    }

    private func buildDetail(from recipe: Recipe) async -> CraftRecipeDetail {
        let item = await itemsRepository.getHeroItem(recipe.resultItemId)
        let currentInventory = await currentInventory()
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

        var ingredientDisplays: [CraftIngredientDisplay] = []
        for ingredient in recipe.ingredients {
            let material = await materialRepository.getById(id: ingredient.itemId)
            let inBag = currentInventory.materials.first(where: { $0.id == ingredient.itemId })?.quantity ?? 0
            ingredientDisplays.append(CraftIngredientDisplay(
                id: ingredient.itemId,
                imageName: material?.imageName ?? "questionmark",
                title: material?.title ?? "Unknown",
                required: ingredient.amount,
                inBag: inBag
            ))
        }

        let canCraft = craftService.canCraft(recipe: recipe, inventory: currentInventory)
        let missing = craftService.getMissingIngredients(recipe: recipe, inventory: currentInventory)

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
