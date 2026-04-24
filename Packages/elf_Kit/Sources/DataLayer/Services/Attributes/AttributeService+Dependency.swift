//
//  AttributeService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var attributeService: any AttributeService {
        get { self[AttributeServiceKey.self] }
        set { self[AttributeServiceKey.self] = newValue }
    }
}

private enum AttributeServiceKey: DependencyKey {
    static var liveValue: any AttributeService { ElfAttributeService() }
}
