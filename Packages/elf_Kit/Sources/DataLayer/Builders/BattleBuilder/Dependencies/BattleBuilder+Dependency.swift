//
//  BattleBuilder+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var battleBuilder: any BattleBuilder {
        get { self[BattleBuilderKey.self] }
        set { self[BattleBuilderKey.self] = newValue }
    }
}

private enum BattleBuilderKey: DependencyKey {
    static var liveValue: any BattleBuilder { DefaultBattleBuilder() }
}
