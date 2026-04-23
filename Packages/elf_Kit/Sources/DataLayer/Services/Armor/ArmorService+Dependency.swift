//
//  ArmorService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var armorService: any ArmorService {
        get { self[ArmorServiceKey.self] }
        set { self[ArmorServiceKey.self] = newValue }
    }
}

private enum ArmorServiceKey: DependencyKey {
    static var liveValue: any ArmorService {
        fatalError("ArmorService must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It depends on async-loaded ItemsRepository.")
    }
}
