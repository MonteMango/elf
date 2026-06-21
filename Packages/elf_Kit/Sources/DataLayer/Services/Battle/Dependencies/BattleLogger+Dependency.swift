//
//  BattleLogger+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var battleLogger: any BattleLogger {
        get { self[BattleLoggerKey.self] }
        set { self[BattleLoggerKey.self] = newValue }
    }
}

private enum BattleLoggerKey: DependencyKey {
    static var liveValue: any BattleLogger { ElfBattleLogger() }
}
