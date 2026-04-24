//
//  GameInitializationService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var gameInitializationService: any GameInitializationService {
        get { self[GameInitializationServiceKey.self] }
        set { self[GameInitializationServiceKey.self] = newValue }
    }
}

private enum GameInitializationServiceKey: DependencyKey {
    static var liveValue: any GameInitializationService { ElfGameInitializationService() }
}
