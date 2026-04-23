//
//  ElfInfoFactory+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var elfInfoFactory: any ElfInfoFactory {
        get { self[ElfInfoFactoryKey.self] }
        set { self[ElfInfoFactoryKey.self] = newValue }
    }
}

private enum ElfInfoFactoryKey: DependencyKey {
    static var liveValue: any ElfInfoFactory {
        @Dependency(\.attributeService) var attributeService
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.inventoryService) var inventoryService
        return DefaultElfInfoFactory(
            attributeService: attributeService,
            itemsRepository: itemsRepository,
            inventoryService: inventoryService
        )
    }
}
