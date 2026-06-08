//
//  HeroEquippedSlotResolver+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var equippedSlotResolver: any HeroEquippedSlotResolver {
        get { self[HeroEquippedSlotResolverKey.self] }
        set { self[HeroEquippedSlotResolverKey.self] = newValue }
    }
}

private enum HeroEquippedSlotResolverKey: DependencyKey {
    static var liveValue: any HeroEquippedSlotResolver { DefaultHeroEquippedSlotResolver() }
}
