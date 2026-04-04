//
//  QuestRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol QuestRepository: Repository<Quest> {

    /// Get all quests belonging to a specific quest character.
    func quests(for ownerId: QuestCharacterID) async -> [Quest]

    /// Get all quest characters.
    func allCharacters() async -> [QuestCharacter]

    /// Get a quest character by ID.
    func character(by id: QuestCharacterID) async -> QuestCharacter?
}
