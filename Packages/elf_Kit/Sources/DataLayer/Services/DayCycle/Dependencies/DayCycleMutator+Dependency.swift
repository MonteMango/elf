//
//  DayCycleMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var dayCycleMutator: any DayCycleMutator {
        get { self[DayCycleMutatorKey.self] }
        set { self[DayCycleMutatorKey.self] = newValue }
    }
}

private enum DayCycleMutatorKey: DependencyKey {
    static var liveValue: any DayCycleMutator { DefaultDayCycleMutator() }
    static var testValue: any DayCycleMutator { liveValue }
}
