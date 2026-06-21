//
//  BuffsRepository+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var buffsRepository: any BuffsRepository {
        get { self[BuffsRepositoryKey.self] }
        set { self[BuffsRepositoryKey.self] = newValue }
    }
}

private enum BuffsRepositoryKey: DependencyKey {
    static var liveValue: any BuffsRepository {
        fatalError("BuffsRepository must be registered via prepareDependencies at app bootstrap (see DependencyBootstrap). It is sourced from async-loaded GameDataRepository.")
    }

    /// Empty catalog by default — tests that don't need real buffs can construct
    /// `GameSession` without spelling out a `withDependencies` override. Tests
    /// that need specific buffs override via `withDependencies { $0.buffsRepository = … }`.
    static var testValue: any BuffsRepository {
        ElfBuffsRepository(buffsData: BuffsData(version: "1.0-empty", buffs: []))
    }
}
