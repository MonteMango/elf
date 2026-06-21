//
//  DebugBattleLogger+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var debugBattleLogger: any DebugBattleLogger {
        get { self[DebugBattleLoggerKey.self] }
        set { self[DebugBattleLoggerKey.self] = newValue }
    }
}

private enum DebugBattleLoggerKey: DependencyKey {
    static var liveValue: any DebugBattleLogger {
        ConsoleDebugBattleLogger(categories: [])
    }
    static var testValue: any DebugBattleLogger { NoOpDebugBattleLogger() }
}
