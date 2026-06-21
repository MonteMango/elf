//
//  CharacterNameValidator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var characterNameValidator: any CharacterNameValidator {
        get { self[CharacterNameValidatorKey.self] }
        set { self[CharacterNameValidatorKey.self] = newValue }
    }
}

private enum CharacterNameValidatorKey: DependencyKey {
    static var liveValue: any CharacterNameValidator { DefaultCharacterNameValidator() }
}
