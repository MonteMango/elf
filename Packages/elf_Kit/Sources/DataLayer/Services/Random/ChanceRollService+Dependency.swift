//
//  ChanceRollService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var chanceRollService: any ChanceRollService {
        get { self[ChanceRollServiceKey.self] }
        set { self[ChanceRollServiceKey.self] = newValue }
    }
}

private enum ChanceRollServiceKey: DependencyKey {
    static var liveValue: any ChanceRollService { ElfChanceRollService() }
}
