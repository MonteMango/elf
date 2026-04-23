//
//  HuntService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var huntService: any HuntService {
        get { self[HuntServiceKey.self] }
        set { self[HuntServiceKey.self] = newValue }
    }
}

private enum HuntServiceKey: DependencyKey {
    static var liveValue: any HuntService {
        @Dependency(\.itemsRepository) var itemsRepository
        return ElfHuntService(itemsRepository: itemsRepository)
    }
}
