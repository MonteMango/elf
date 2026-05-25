//
//  GameDataRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol GameDataRepository: Sendable {
    var items: any ItemsRepository { get }
    var monsters: any MonsterRepository { get }
    var fish: any Repository<Fish> { get }
    var herbs: any Repository<Herb> { get }
    var ores: any Repository<Ore> { get }
    var recipes: any RecipeRepository { get }
    var materials: any Repository<Material> { get }
    var quests: any QuestRepository { get }
    var dungeons: any DungeonRepository { get }
    var buffs: any BuffsRepository { get }
}
