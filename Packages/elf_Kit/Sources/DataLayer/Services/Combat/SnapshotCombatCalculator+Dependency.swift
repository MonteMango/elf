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
        fatalError("SnapshotCombatCalculator must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It composes several bootstrap-required services.")
    }
}
