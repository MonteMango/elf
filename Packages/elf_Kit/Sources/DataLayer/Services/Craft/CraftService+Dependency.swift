//
//  CraftService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var craftService: any CraftService {
        get { self[CraftServiceKey.self] }
        set { self[CraftServiceKey.self] = newValue }
    }
}

private enum CraftServiceKey: DependencyKey {
    static var liveValue: any CraftService { DefaultCraftService() }
}
