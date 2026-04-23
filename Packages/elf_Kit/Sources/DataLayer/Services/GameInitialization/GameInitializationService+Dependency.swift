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
    static var liveValue: any GameInitializationService {
        @Dependency(\.houseService) var houseService
        @Dependency(\.elfInfoFactory) var elfInfoFactory
        @Dependency(\.calendarService) var calendarService
        @Dependency(\.gameRepository) var gameRepository
        return ElfGameInitializationService(
            houseService: houseService,
            elfInfoFactory: elfInfoFactory,
            calendarService: calendarService,
            gameRepository: gameRepository
        )
    }
}
