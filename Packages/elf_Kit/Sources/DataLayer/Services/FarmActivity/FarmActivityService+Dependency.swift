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
    static var liveValue: any FarmActivityService {
        fatalError("FarmActivityService must be registered via prepareDependencies at app bootstrap (see ElfApp.swift). It depends on async-loaded GameDataRepository and cannot be constructed from liveValue directly.")
    }
}
