//
//  DataLoader+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var dataLoader: any DataLoader {
        get { self[DataLoaderKey.self] }
        set { self[DataLoaderKey.self] = newValue }
    }
}

private enum DataLoaderKey: DependencyKey {
    static var liveValue: any DataLoader { ElfDataLoader() }
}
