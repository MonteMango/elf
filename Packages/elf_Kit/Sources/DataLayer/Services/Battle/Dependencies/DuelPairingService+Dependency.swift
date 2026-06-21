//
//  DuelPairingService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var duelPairingService: any DuelPairingService {
        get { self[DuelPairingServiceKey.self] }
        set { self[DuelPairingServiceKey.self] = newValue }
    }
}

private enum DuelPairingServiceKey: DependencyKey {
    static var liveValue: any DuelPairingService { RandomDuelPairingService() }
}
