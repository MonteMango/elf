//
//  Quest.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct Quest: Codable, Sendable, Identifiable, Hashable {
    public let id: QuestID
    public let questOwnerId: QuestCharacterID
    public let title: String
    public let description: String
    public let conditions: [QuestCondition]
    public let rewards: [QuestReward]

    public init(
        id: QuestID,
        questOwnerId: QuestCharacterID,
        title: String,
        description: String,
        conditions: [QuestCondition],
        rewards: [QuestReward]
    ) {
        self.id = id
        self.questOwnerId = questOwnerId
        self.title = title
        self.description = description
        self.conditions = conditions
        self.rewards = rewards
    }
}
