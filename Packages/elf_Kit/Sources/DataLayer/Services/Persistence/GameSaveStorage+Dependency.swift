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

    #if DEBUG
    static var previewValue: any GameSaveStorage { PreviewGameSaveStorage() }
    #endif
}

#if DEBUG
private struct PreviewGameSaveStorage: GameSaveStorage {
    func save(_ game: Game, slotId: String, playTime: TimeInterval) async throws {}
    func load(slotId: String) async throws -> Game {
        throw CocoaError(.fileReadNoSuchFile)
    }
    func hasAnySave() -> Bool { false }
    func getPlayTime(slotId: String) async -> TimeInterval { 0 }
}
#endif
