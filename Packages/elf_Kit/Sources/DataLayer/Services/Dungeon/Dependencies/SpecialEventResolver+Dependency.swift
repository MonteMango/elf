//
//  SpecialEventResolver+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var specialEventResolver: any SpecialEventResolver {
        get { self[SpecialEventResolverKey.self] }
        set { self[SpecialEventResolverKey.self] = newValue }
    }
}

private enum SpecialEventResolverKey: DependencyKey {
    static var liveValue: any SpecialEventResolver { DefaultSpecialEventResolver() }
}
