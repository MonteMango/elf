//
//  DefaultGameDataRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation
import os.log

public final class DefaultGameDataRepository: GameDataRepository {

    public let items: any ItemsRepository
    public let monsters: any MonsterRepository
    public let fish: any Repository<Fish>
    public let herbs: any Repository<Herb>
    public let ores: any Repository<Ore>
    public let recipes: any RecipeRepository
    public let materials: any Repository<Material>
    public let quests: any QuestRepository
    public let dungeons: any DungeonRepository

    /// Async init — loads all JSON data on the cooperative thread pool,
    /// then creates immutable repositories. `DataLoader` is resolved via
    /// `@Dependency(\.dataLoader)`, so tests can override with a stub.
    public init() async {
        @Dependency(\.dataLoader) var dataLoader
        let log = OSLog(subsystem: "com.elfy.kit", category: "GameData")

        let fishData: FishData = await dataLoader.loadAndDecode(
            resourceName: "Fish", fallback: .empty, log: log
        )
        let herbData: HerbData = await dataLoader.loadAndDecode(
            resourceName: "Herbs", fallback: .empty, log: log
        )
        let oreData: OreData = await dataLoader.loadAndDecode(
            resourceName: "Ores", fallback: .empty, log: log
        )
        let materialsData: MaterialsData = await dataLoader.loadAndDecode(
            resourceName: "Materials", fallback: MaterialsData(), log: log
        )
        let heroItems: HeroItems = await dataLoader.loadAndDecode(
            resourceName: "HeroItems", fallback: .empty, log: log
        )
        let monstersData: MonstersData = await dataLoader.loadAndDecode(
            resourceName: "Monsters", fallback: .empty(), log: log
        )
        let recipesData: RecipesData = await dataLoader.loadAndDecode(
            resourceName: "Recipes", fallback: RecipesData(), log: log
        )
        let questsData: QuestsData = await dataLoader.loadAndDecode(
            resourceName: "Quests", fallback: QuestsData(), log: log
        )
        let dungeonsData: DungeonsData = await dataLoader.loadAndDecode(
            resourceName: "Dungeons", fallback: .empty(), log: log
        )

        self.fish = ArrayRepository(items: fishData.items)
        self.herbs = ArrayRepository(items: herbData.items)
        self.ores = ArrayRepository(items: oreData.items)
        self.materials = ArrayRepository(items: materialsData.monstersDrop)
        self.items = ElfItemsRepository(heroItems: heroItems)
        self.monsters = ElfMonsterRepository(monstersData: monstersData)
        self.recipes = ElfRecipeRepository(recipesData: recipesData)
        self.quests = ElfQuestRepository(questsData: questsData)
        self.dungeons = ElfDungeonRepository(dungeonsData: dungeonsData)
    }
}
