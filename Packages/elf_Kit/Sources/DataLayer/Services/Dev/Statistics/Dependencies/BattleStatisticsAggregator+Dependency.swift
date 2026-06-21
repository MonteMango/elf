//
//  BattleStatisticsAggregator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var statisticsAggregator: any BattleStatisticsAggregator {
        get { self[BattleStatisticsAggregatorKey.self] }
        set { self[BattleStatisticsAggregatorKey.self] = newValue }
    }
}

private enum BattleStatisticsAggregatorKey: DependencyKey {
    static var liveValue: any BattleStatisticsAggregator { ElfBattleStatisticsAggregator() }
}
