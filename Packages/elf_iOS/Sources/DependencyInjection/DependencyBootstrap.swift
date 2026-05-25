//
//  DependencyBootstrap.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import elf_Kit
import Foundation

/// One-shot app bootstrap: asynchronously loads game data and registers the
/// async-loaded root dependencies via `prepareDependencies`. All downstream
/// services (attribute, damage, farm activity, battle simulation, game init,
/// etc.) auto-compose through their `@Dependency`-based `liveValue` — no
/// manual wiring here.
///
/// Called exactly once at app launch from the splash-gate `.task {}` in `ElfApp`.
/// Must complete before any `@Dependency(\.xxx)` read — `ElfApp` gates the root
/// UI behind a splash view to guarantee this.
@MainActor
public enum DependencyBootstrap {

    public static func run() async {
        let gameData = await DefaultGameDataRepository()

        prepareDependencies {
            $0.gameDataRepository = gameData
            $0.itemsRepository = gameData.items
            $0.monsterRepository = gameData.monsters
            $0.fishRepository = gameData.fish
            $0.herbRepository = gameData.herbs
            $0.oreRepository = gameData.ores
            $0.materialRepository = gameData.materials
            $0.recipeRepository = gameData.recipes
            $0.questRepository = gameData.quests
            $0.dungeonRepository = gameData.dungeons
            $0.buffsRepository = gameData.buffs
        }
    }
}
