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
    static var liveValue: any ElfInfoFactory { DefaultElfInfoFactory() }
}
