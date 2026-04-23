//
//  SnapshotCombatCalculator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var snapshotCombatCalculator: any SnapshotCombatCalculator {
        get { self[SnapshotCombatCalculatorKey.self] }
        set { self[SnapshotCombatCalculatorKey.self] = newValue }
    }
}

private enum SnapshotCombatCalculatorKey: DependencyKey {
    static var liveValue: any SnapshotCombatCalculator {
        @Dependency(\.damageService) var damageService
        @Dependency(\.dodgeService) var dodgeService
        @Dependency(\.critService) var critService
        @Dependency(\.debugBattleLogger) var debugBattleLogger
        return ElfSnapshotCombatCalculator(
            damageService: damageService,
            dodgeService: dodgeService,
            critService: critService,
            debugLogger: debugBattleLogger
        )
    }
}
