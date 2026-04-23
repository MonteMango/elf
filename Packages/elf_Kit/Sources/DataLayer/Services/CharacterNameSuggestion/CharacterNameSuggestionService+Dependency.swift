//
//  CharacterNameSuggestionService+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var characterNameSuggestionService: any CharacterNameSuggestionService {
        get { self[CharacterNameSuggestionServiceKey.self] }
        set { self[CharacterNameSuggestionServiceKey.self] = newValue }
    }
}

private enum CharacterNameSuggestionServiceKey: DependencyKey {
    static var liveValue: any CharacterNameSuggestionService { DefaultCharacterNameSuggestionService() }
}
