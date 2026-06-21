//
//  BattleStatisticsParser+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var statisticsParser: any BattleStatisticsParser {
        get { self[BattleStatisticsParserKey.self] }
        set { self[BattleStatisticsParserKey.self] = newValue }
    }
}

private enum BattleStatisticsParserKey: DependencyKey {
    static var liveValue: any BattleStatisticsParser { ElfBattleStatisticsParser() }
}
