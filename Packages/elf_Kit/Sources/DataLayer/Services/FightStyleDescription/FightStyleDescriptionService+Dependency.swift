//
//  FightStyleDescriptionService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var fightStyleDescriptionService: any FightStyleDescriptionService {
        get { self[FightStyleDescriptionServiceKey.self] }
        set { self[FightStyleDescriptionServiceKey.self] = newValue }
    }
}

private enum FightStyleDescriptionServiceKey: DependencyKey {
    static var liveValue: any FightStyleDescriptionService { DefaultFightStyleDescriptionService() }
}
