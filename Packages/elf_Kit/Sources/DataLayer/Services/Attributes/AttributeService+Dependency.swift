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
    static var liveValue: any AttributeService {
        fatalError("AttributeService must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It depends on async-loaded ItemsRepository.")
    }
}
