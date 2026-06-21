//
//  LoadedSave.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// A loaded save: the game plus an optional in-progress dungeon run to resume.
/// Returned by `GameSaveStorage.load`.
public struct LoadedSave: Sendable {
    public let game: Game
    public let dungeonRun: DungeonRunSaveData?

    public init(game: Game, dungeonRun: DungeonRunSaveData?) {
        self.game = game
        self.dungeonRun = dungeonRun
    }
}
