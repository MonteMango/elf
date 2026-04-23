//
//  ProgressionService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var progressionService: any ProgressionService {
        get { self[ProgressionServiceKey.self] }
        set { self[ProgressionServiceKey.self] = newValue }
    }
}

private enum ProgressionServiceKey: DependencyKey {
    static var liveValue: any ProgressionService { ElfProgressionService() }
}
