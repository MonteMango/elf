//
//  MonsterRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var monsterRepository: any MonsterRepository {
        get { self[MonsterRepositoryKey.self] }
        set { self[MonsterRepositoryKey.self] = newValue }
    }
}

private enum MonsterRepositoryKey: DependencyKey {
    static var liveValue: any MonsterRepository {
        fatalError("MonsterRepository must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It is sourced from async-loaded GameDataRepository.")
    }
}
