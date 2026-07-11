//
//  DuelPairingMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var duelPairingMutator: any DuelPairingMutator {
        get { self[DuelPairingMutatorKey.self] }
        set { self[DuelPairingMutatorKey.self] = newValue }
    }
}

private enum DuelPairingMutatorKey: DependencyKey {
    static var liveValue: any DuelPairingMutator { DefaultDuelPairingMutator() }
    static var testValue: any DuelPairingMutator { liveValue }
}
