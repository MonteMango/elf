//
//  FishRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var fishRepository: any Repository<Fish> {
        get { self[FishRepositoryKey.self] }
        set { self[FishRepositoryKey.self] = newValue }
    }
}

private enum FishRepositoryKey: DependencyKey {
    static var liveValue: any Repository<Fish> {
        fatalError("FishRepository must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It is sourced from async-loaded GameDataRepository.")
    }
}
