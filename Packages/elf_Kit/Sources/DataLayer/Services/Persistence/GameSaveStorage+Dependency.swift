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
        fatalError("GameRepository must be registered via prepareDependencies at app bootstrap (see DependencyBootstrap.swift).")
    }
}
