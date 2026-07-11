//
//  RunProgressionMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var runProgressionMutator: any RunProgressionMutator {
        get { self[RunProgressionMutatorKey.self] }
        set { self[RunProgressionMutatorKey.self] = newValue }
    }
}

private enum RunProgressionMutatorKey: DependencyKey {
    static var liveValue: any RunProgressionMutator { DefaultRunProgressionMutator() }
    static var testValue: any RunProgressionMutator { liveValue }
}
