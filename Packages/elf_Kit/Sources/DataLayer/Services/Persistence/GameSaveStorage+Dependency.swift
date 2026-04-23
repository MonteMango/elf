//
//  GameSaveStorage+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var gameRepository: any GameSaveStorage {
        get { self[GameRepositoryKey.self] }
        set { self[GameRepositoryKey.self] = newValue }
    }
}

private enum GameRepositoryKey: DependencyKey {
    static var liveValue: any GameSaveStorage {
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.progressionService) var progressionService
        @Dependency(\.inventoryService) var inventoryService
        return FileGameSaveStorage(
            itemsRepository: itemsRepository,
            progressionService: progressionService,
            inventoryService: inventoryService
        )
    }
}
