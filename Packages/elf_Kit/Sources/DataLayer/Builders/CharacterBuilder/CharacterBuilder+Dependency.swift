//
//  CharacterBuilder+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    /// Factory for `CharacterBuilder`. The builder is stateful (accumulates
    /// appearance/name/fight-style across wizard stages), so each VM needs its
    /// own instance — we inject a factory rather than a shared value.
    public var characterBuilderFactory: @MainActor @Sendable () -> any CharacterBuilder {
        get { self[CharacterBuilderFactoryKey.self] }
        set { self[CharacterBuilderFactoryKey.self] = newValue }
    }
}

private enum CharacterBuilderFactoryKey: DependencyKey {
    static var liveValue: @MainActor @Sendable () -> any CharacterBuilder {
        { DefaultCharacterBuilder() }
    }
}
