//
//  QuestRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var questRepository: any QuestRepository {
        get { self[QuestRepositoryKey.self] }
        set { self[QuestRepositoryKey.self] = newValue }
    }
}

private enum QuestRepositoryKey: DependencyKey {
    static var liveValue: any QuestRepository {
        fatalError("QuestRepository must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It is sourced from async-loaded GameDataRepository.")
    }
}
