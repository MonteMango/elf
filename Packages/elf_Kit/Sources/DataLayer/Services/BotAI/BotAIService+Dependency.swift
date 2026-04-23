//
//  BotAIService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var botAI: any BotAIService {
        get { self[BotAIServiceKey.self] }
        set { self[BotAIServiceKey.self] = newValue }
    }
}

private enum BotAIServiceKey: DependencyKey {
    static var liveValue: any BotAIService { ElfRandomBotAI() }
}
