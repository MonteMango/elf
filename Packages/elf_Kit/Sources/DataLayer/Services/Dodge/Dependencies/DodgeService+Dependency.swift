//
//  DodgeService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var dodgeService: any DodgeService {
        get { self[DodgeServiceKey.self] }
        set { self[DodgeServiceKey.self] = newValue }
    }
}

private enum DodgeServiceKey: DependencyKey {
    static var liveValue: any DodgeService { ElfDodgeService() }
}
