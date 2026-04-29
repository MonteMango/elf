//
//  BattleRoundRunner+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var battleRoundRunner: any BattleRoundRunner {
        get { self[BattleRoundRunnerKey.self] }
        set { self[BattleRoundRunnerKey.self] = newValue }
    }
}

private enum BattleRoundRunnerKey: DependencyKey {
    static var liveValue: any BattleRoundRunner { DefaultBattleRoundRunner() }
    static var testValue: any BattleRoundRunner { liveValue }
}
