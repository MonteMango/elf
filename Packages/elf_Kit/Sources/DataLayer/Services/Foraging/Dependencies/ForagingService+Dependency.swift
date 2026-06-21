//
//  ForagingService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var foragingService: any ForagingService {
        get { self[ForagingServiceKey.self] }
        set { self[ForagingServiceKey.self] = newValue }
    }
}

private enum ForagingServiceKey: DependencyKey {
    static var liveValue: any ForagingService { DefaultForagingService() }
}
