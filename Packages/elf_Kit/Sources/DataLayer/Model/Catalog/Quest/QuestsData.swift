//
//  QuestsData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct QuestsData: Codable, Sendable {
    public let version: String
    public let questCharacters: [QuestCharacter]
    public let quests: [Quest]

    enum CodingKeys: String, CodingKey {
        case version
        case questCharacters = "quest_characters"
        case quests
    }

    /// Empty initializer for fallback
    public init() {
        self.version = "1.0-empty"
        self.questCharacters = []
        self.quests = []
    }

    public init(version: String, questCharacters: [QuestCharacter], quests: [Quest]) {
        self.version = version
        self.questCharacters = questCharacters
        self.quests = quests
    }
}
