//
//  BattleSimulationService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var battleSimulationService: any BattleSimulationService {
        get { self[BattleSimulationServiceKey.self] }
        set { self[BattleSimulationServiceKey.self] = newValue }
    }
}

private enum BattleSimulationServiceKey: DependencyKey {
    static var liveValue: any BattleSimulationService {
        @Dependency(\.botAI) var botAI
        @Dependency(\.snapshotCombatCalculator) var snapshotCombatCalculator
        @Dependency(\.damageService) var damageService
        @Dependency(\.statisticsParser) var statisticsParser
        return ElfBattleSimulationService(
            botAI: botAI,
            snapshotCombatCalculator: snapshotCombatCalculator,
            damageService: damageService,
            statisticsParser: statisticsParser
        )
    }
}
