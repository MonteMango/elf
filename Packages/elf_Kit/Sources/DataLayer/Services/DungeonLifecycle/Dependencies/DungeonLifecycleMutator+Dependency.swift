//
//  DungeonLifecycleMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var dungeonLifecycleMutator: any DungeonLifecycleMutator {
        get { self[DungeonLifecycleMutatorKey.self] }
        set { self[DungeonLifecycleMutatorKey.self] = newValue }
    }
}

@MainActor
private enum DungeonLifecycleMutatorKey: @preconcurrency DependencyKey {
    static var liveValue: any DungeonLifecycleMutator { DefaultDungeonLifecycleMutator() }
    static var testValue: any DungeonLifecycleMutator { liveValue }
}
