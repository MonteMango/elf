//
//  DebugGameLogger+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var debugGameLogger: any DebugGameLogger {
        get { self[DebugGameLoggerKey.self] }
        set { self[DebugGameLoggerKey.self] = newValue }
    }
}

private enum DebugGameLoggerKey: DependencyKey {
    static var liveValue: any DebugGameLogger {
        ConsoleDebugGameLogger(categories: [.playerInfo, .gameState, .inventory, .equipment, .houses])
    }
}
