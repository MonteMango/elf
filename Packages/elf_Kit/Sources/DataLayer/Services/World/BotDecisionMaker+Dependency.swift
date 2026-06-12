//
//  BotDecisionMaker+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Dependencies

extension DependencyValues {
    public var botDecisionMaker: any BotDecisionMaker {
        get { self[BotDecisionMakerKey.self] }
        set { self[BotDecisionMakerKey.self] = newValue }
    }
}

private enum BotDecisionMakerKey: DependencyKey {
    static var liveValue: any BotDecisionMaker { DefaultBotDecisionMaker() }
}
