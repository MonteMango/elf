//
//  ItemsRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var itemsRepository: any ItemsRepository {
        get { self[ItemsRepositoryKey.self] }
        set { self[ItemsRepositoryKey.self] = newValue }
    }
}

private enum ItemsRepositoryKey: DependencyKey {
    static var liveValue: any ItemsRepository {
        fatalError("ItemsRepository must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It is sourced from async-loaded GameDataRepository.")
    }
}
