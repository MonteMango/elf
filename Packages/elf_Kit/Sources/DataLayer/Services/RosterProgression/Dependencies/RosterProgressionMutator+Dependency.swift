//
//  RosterProgressionMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var rosterProgressionMutator: any RosterProgressionMutator {
        get { self[RosterProgressionMutatorKey.self] }
        set { self[RosterProgressionMutatorKey.self] = newValue }
    }
}

private enum RosterProgressionMutatorKey: DependencyKey {
    static var liveValue: any RosterProgressionMutator { DefaultRosterProgressionMutator() }
    static var testValue: any RosterProgressionMutator { liveValue }
}
