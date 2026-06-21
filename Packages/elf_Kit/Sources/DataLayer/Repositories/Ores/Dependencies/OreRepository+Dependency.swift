//
//  OreRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var oreRepository: any Repository<Ore> {
        get { self[OreRepositoryKey.self] }
        set { self[OreRepositoryKey.self] = newValue }
    }
}

private enum OreRepositoryKey: DependencyKey {
    static var liveValue: any Repository<Ore> {
        fatalError("OreRepository must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It is sourced from async-loaded GameDataRepository.")
    }
}
