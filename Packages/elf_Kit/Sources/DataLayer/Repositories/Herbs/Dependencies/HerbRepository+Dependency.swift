//
//  HerbRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var herbRepository: any Repository<Herb> {
        get { self[HerbRepositoryKey.self] }
        set { self[HerbRepositoryKey.self] = newValue }
    }
}

private enum HerbRepositoryKey: DependencyKey {
    static var liveValue: any Repository<Herb> {
        fatalError("HerbRepository must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It is sourced from async-loaded GameDataRepository.")
    }
}
