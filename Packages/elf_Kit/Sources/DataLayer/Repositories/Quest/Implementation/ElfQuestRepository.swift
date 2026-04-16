//
//  ElfQuestRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfQuestRepository: QuestRepository {

    private let allQuests: [Quest]
    private let questLookup: [QuestID: Quest]
    private let questsByOwner: [QuestCharacterID: [Quest]]
    private let characters: [QuestCharacter]
    private let characterLookup: [QuestCharacterID: QuestCharacter]

    public init(questsData: QuestsData) {
        self.allQuests = questsData.quests
        self.characters = questsData.questCharacters

        var questLookup: [QuestID: Quest] = [:]
        var questsByOwner: [QuestCharacterID: [Quest]] = [:]
        for quest in questsData.quests {
            questLookup[quest.id] = quest
            questsByOwner[quest.questOwnerId, default: []].append(quest)
        }
        self.questLookup = questLookup
        self.questsByOwner = questsByOwner

        var characterLookup: [QuestCharacterID: QuestCharacter] = [:]
        for character in questsData.questCharacters {
            characterLookup[character.id] = character
        }
        self.characterLookup = characterLookup
    }

    // MARK: - Repository<Quest>

    public func getAll() -> [Quest] { allQuests }

    public func getById(id: QuestID) -> Quest? { questLookup[id] }

    // MARK: - QuestRepository

    public func quests(for ownerId: QuestCharacterID) -> [Quest] {
        questsByOwner[ownerId] ?? []
    }

    public func allCharacters() -> [QuestCharacter] { characters }

    public func character(by id: QuestCharacterID) -> QuestCharacter? {
        characterLookup[id]
    }
}
