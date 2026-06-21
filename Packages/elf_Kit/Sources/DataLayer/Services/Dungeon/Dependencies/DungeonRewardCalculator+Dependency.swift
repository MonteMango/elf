//
//  DungeonRewardCalculator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var dungeonRewardCalculator: any DungeonRewardCalculator {
        get { self[DungeonRewardCalculatorKey.self] }
        set { self[DungeonRewardCalculatorKey.self] = newValue }
    }
}

private enum DungeonRewardCalculatorKey: DependencyKey {
    static var liveValue: any DungeonRewardCalculator { DefaultDungeonRewardCalculator() }
}
