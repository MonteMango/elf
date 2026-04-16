//
//  QuestRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol QuestRepository: Repository<Quest> {

    /// Get all quests belonging to a specific quest character.
    func quests(for ownerId: QuestCharacterID) -> [Quest]

    /// Get all quest characters.
    func allCharacters() -> [QuestCharacter]

    /// Get a quest character by ID.
    func character(by id: QuestCharacterID) -> QuestCharacter?
}
