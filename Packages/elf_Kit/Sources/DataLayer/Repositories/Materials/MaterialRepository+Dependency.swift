//
//  MaterialRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var materialRepository: any Repository<Material> {
        get { self[MaterialRepositoryKey.self] }
        set { self[MaterialRepositoryKey.self] = newValue }
    }
}

private enum MaterialRepositoryKey: DependencyKey {
    static var liveValue: any Repository<Material> {
        fatalError("MaterialRepository must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It is sourced from async-loaded GameDataRepository.")
    }
}
