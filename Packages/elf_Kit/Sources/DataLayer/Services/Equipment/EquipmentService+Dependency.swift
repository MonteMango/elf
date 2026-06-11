//
//  EquipmentService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var equipmentService: any EquipmentService {
        get { self[EquipmentServiceKey.self] }
        set { self[EquipmentServiceKey.self] = newValue }
    }
}

private enum EquipmentServiceKey: DependencyKey {
    static var liveValue: any EquipmentService { ElfEquipmentService() }
}
