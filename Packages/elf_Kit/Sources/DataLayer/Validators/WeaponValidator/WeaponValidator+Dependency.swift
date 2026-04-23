//
//  WeaponValidator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var weaponValidator: any WeaponValidator {
        get { self[WeaponValidatorKey.self] }
        set { self[WeaponValidatorKey.self] = newValue }
    }
}

private enum WeaponValidatorKey: DependencyKey {
    static var liveValue: any WeaponValidator {
        fatalError("WeaponValidator must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It depends on async-loaded ItemsRepository.")
    }
}
