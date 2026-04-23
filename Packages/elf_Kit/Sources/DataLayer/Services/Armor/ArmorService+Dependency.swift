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
        @Dependency(\.itemsRepository) var itemsRepository
        return ElfArmorService(itemsRepository: itemsRepository)
    }
}
