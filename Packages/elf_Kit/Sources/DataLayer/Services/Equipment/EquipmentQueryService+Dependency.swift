//
//  EquipmentQueryService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var equipmentQueryService: any EquipmentQueryService {
        get { self[EquipmentQueryServiceKey.self] }
        set { self[EquipmentQueryServiceKey.self] = newValue }
    }
}

private enum EquipmentQueryServiceKey: DependencyKey {
    static var liveValue: any EquipmentQueryService { ElfEquipmentQueryService() }
    static var testValue: any EquipmentQueryService { liveValue }
}
