//
//  FarmActivityService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var farmActivityService: any FarmActivityService {
        get { self[FarmActivityServiceKey.self] }
        set { self[FarmActivityServiceKey.self] = newValue }
    }
}

private enum FarmActivityServiceKey: DependencyKey {
    static var liveValue: any FarmActivityService { DefaultFarmActivityService() }
}
