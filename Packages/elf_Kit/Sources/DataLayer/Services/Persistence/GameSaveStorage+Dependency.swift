//
//  GameSaveStorage+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

extension DependencyValues {
    public var gameRepository: any GameSaveStorage {
        get { self[GameRepositoryKey.self] }
        set { self[GameRepositoryKey.self] = newValue }
    }
}

private enum GameRepositoryKey: DependencyKey {
    static var liveValue: any GameSaveStorage { FileGameSaveStorage() }
    static var testValue: any GameSaveStorage { NoOpGameSaveStorage() }

    #if DEBUG
    static var previewValue: any GameSaveStorage { NoOpGameSaveStorage() }
    #endif
}

/// NoOp storage used as `testValue` (always) and `previewValue` (debug). Used by
/// snapshot-in-init types that resolve `gameRepository` even in code paths that
/// never persist.
private struct NoOpGameSaveStorage: GameSaveStorage {
    func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws {}
    func load(slotId: String) async throws -> LoadedSave {
        throw CocoaError(.fileReadNoSuchFile)
    }
    func hasAnySave() -> Bool { false }
    func getPlayTime(slotId: String) async -> TimeInterval { 0 }
}
