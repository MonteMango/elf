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
    static var liveValue: any CombatRoundExecutor { ElfCombatRoundExecutor() }
}
