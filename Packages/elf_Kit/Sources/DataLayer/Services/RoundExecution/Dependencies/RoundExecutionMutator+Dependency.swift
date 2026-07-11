//
//  RoundExecutionMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var roundExecutionMutator: any RoundExecutionMutator {
        get { self[RoundExecutionMutatorKey.self] }
        set { self[RoundExecutionMutatorKey.self] = newValue }
    }
}

private enum RoundExecutionMutatorKey: DependencyKey {
    static var liveValue: any RoundExecutionMutator { DefaultRoundExecutionMutator() }
    static var testValue: any RoundExecutionMutator { liveValue }
}
