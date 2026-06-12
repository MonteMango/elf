//
//  BotTurnSimulator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Dependencies

extension DependencyValues {
    public var botTurnSimulator: any BotTurnSimulator {
        get { self[BotTurnSimulatorKey.self] }
        set { self[BotTurnSimulatorKey.self] = newValue }
    }
}

private enum BotTurnSimulatorKey: DependencyKey {
    static var liveValue: any BotTurnSimulator { DefaultBotTurnSimulator() }
}
