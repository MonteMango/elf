//
//  CombatRoundExecutor+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var combatRoundExecutor: any CombatRoundExecutor {
        get { self[CombatRoundExecutorKey.self] }
        set { self[CombatRoundExecutorKey.self] = newValue }
    }
}

private enum CombatRoundExecutorKey: DependencyKey {
    static var liveValue: any CombatRoundExecutor {
        fatalError("CombatRoundExecutor must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It composes several bootstrap-required services.")
    }
}
