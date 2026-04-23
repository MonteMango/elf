//
//  BattleResultCalculator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var battleResultCalculator: any BattleResultCalculator {
        get { self[BattleResultCalculatorKey.self] }
        set { self[BattleResultCalculatorKey.self] = newValue }
    }
}

private enum BattleResultCalculatorKey: DependencyKey {
    static var liveValue: any BattleResultCalculator {
        fatalError("BattleResultCalculator must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It composes several bootstrap-required services.")
    }
}
