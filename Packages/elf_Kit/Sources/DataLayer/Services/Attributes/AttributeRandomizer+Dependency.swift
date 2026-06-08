//
//  AttributeRandomizer+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var attributeRandomizer: any AttributeRandomizer {
        get { self[AttributeRandomizerKey.self] }
        set { self[AttributeRandomizerKey.self] = newValue }
    }
}

private enum AttributeRandomizerKey: DependencyKey {
    static var liveValue: any AttributeRandomizer { ElfAttributeRandomizer() }
}
