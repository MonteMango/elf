//
//  DropService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var dropService: any DropService {
        get { self[DropServiceKey.self] }
        set { self[DropServiceKey.self] = newValue }
    }
}

private enum DropServiceKey: DependencyKey {
    static var liveValue: any DropService { DefaultDropService() }
}
