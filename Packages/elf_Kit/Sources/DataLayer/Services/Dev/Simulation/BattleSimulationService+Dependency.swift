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
    static var liveValue: any BattleSimulationService { ElfBattleSimulationService() }
}
