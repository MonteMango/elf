//
//  GameDataRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var gameDataRepository: any GameDataRepository {
        get { self[GameDataRepositoryKey.self] }
        set { self[GameDataRepositoryKey.self] = newValue }
    }
}

private enum GameDataRepositoryKey: DependencyKey {
    static var liveValue: any GameDataRepository {
        fatalError("GameDataRepository must be registered via prepareDependencies at app bootstrap (see DependencyBootstrap.swift).")
    }
}
