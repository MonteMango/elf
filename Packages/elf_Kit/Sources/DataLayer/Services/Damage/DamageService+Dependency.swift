//
//  DamageService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var damageService: any DamageService {
        get { self[DamageServiceKey.self] }
        set { self[DamageServiceKey.self] = newValue }
    }
}

private enum DamageServiceKey: DependencyKey {
    static var liveValue: any DamageService { ElfDamageService() }
}
