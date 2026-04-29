//
//  InventoryService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var inventoryService: any InventoryService {
        get { self[InventoryServiceKey.self] }
        set { self[InventoryServiceKey.self] = newValue }
    }
}

private enum InventoryServiceKey: DependencyKey {
    static var liveValue: any InventoryService { ElfInventoryService() }
    static var testValue: any InventoryService { liveValue }
}
