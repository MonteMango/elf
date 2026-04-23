//
//  HouseService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var houseService: any HouseService {
        get { self[HouseServiceKey.self] }
        set { self[HouseServiceKey.self] = newValue }
    }
}

private enum HouseServiceKey: DependencyKey {
    static var liveValue: any HouseService {
        @Dependency(\.elfInfoFactory) var elfInfoFactory
        return DefaultHouseService(elfInfoFactory: elfInfoFactory)
    }
}
