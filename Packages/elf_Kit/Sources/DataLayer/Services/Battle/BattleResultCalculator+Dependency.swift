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
        @Dependency(\.huntService) var huntService
        @Dependency(\.dropService) var dropService
        @Dependency(\.progressionService) var progressionService
        return DefaultBattleResultCalculator(
            huntService: huntService,
            dropService: dropService,
            progressionService: progressionService
        )
    }
}
