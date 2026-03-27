//
//  DefaultGameDataRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import os.log

public final class DefaultGameDataRepository: GameDataRepository, Sendable {

    public let items: any ItemsRepository
    public let monsters: any MonsterRepository
    public let fish: any Repository<Fish>
    public let herbs: any Repository<Herb>
    public let ores: any Repository<Ore>
    public let recipes: any RecipeRepository
    public let materials: any Repository<Material>

    /// Async init — loads all JSON data on the cooperative thread pool,
    /// then creates immutable repositories.
    public init(dataLoader: any DataLoader = ElfDataLoader()) async {
        let log = OSLog(subsystem: "com.elfy.kit", category: "GameData")

        let fishData: FishData = dataLoader.loadAndDecode(
            resourceName: "Fish", fallback: .empty, log: log
        )
        let herbData: HerbData = dataLoader.loadAndDecode(
            resourceName: "Herbs", fallback: .empty, log: log
        )
        let oreData: OreData = dataLoader.loadAndDecode(
            resourceName: "Ores", fallback: .empty, log: log
        )
        let materialsData: MaterialsData = dataLoader.loadAndDecode(
            resourceName: "Materials", fallback: MaterialsData(), log: log
        )
        let heroItems: HeroItems = dataLoader.loadAndDecode(
            resourceName: "HeroItems", fallback: .empty, log: log
        )
        let monstersData: MonstersData = dataLoader.loadAndDecode(
            resourceName: "Monsters", fallback: .empty(), log: log
        )
        let recipesData: RecipesData = dataLoader.loadAndDecode(
            resourceName: "Recipes", fallback: RecipesData(), log: log
        )

        self.fish = ArrayRepository(items: fishData.items)
        self.herbs = ArrayRepository(items: herbData.items)
        self.ores = ArrayRepository(items: oreData.items)
        self.materials = ArrayRepository(items: materialsData.monstersDrop)
        self.items = ElfItemsRepository(heroItems: heroItems)
        self.monsters = ElfMonsterRepository(monstersData: monstersData)
        self.recipes = ElfRecipeRepository(recipesData: recipesData)
    }
}
