//
//  DungeonRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var dungeonRepository: any DungeonRepository {
        get { self[DungeonRepositoryKey.self] }
        set { self[DungeonRepositoryKey.self] = newValue }
    }
}

private enum DungeonRepositoryKey: DependencyKey {
    static var liveValue: any DungeonRepository {
        fatalError("DungeonRepository must be registered via prepareDependencies at app bootstrap (see DependencyBootstrap.swift). It is sourced from async-loaded GameDataRepository.")
    }
}
