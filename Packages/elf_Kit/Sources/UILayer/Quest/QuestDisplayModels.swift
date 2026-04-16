//
//  QuestDisplayModels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct QuestConditionDisplay: Identifiable, Equatable, Sendable {
    public let id: String
    public let imageName: String
    public let amount: Int
    public let text: String
}

public struct QuestRewardDisplay: Identifiable, Equatable, Sendable {
    public let id: String
    public let imageName: String
    public let quantity: Int
}

public struct QuestDisplay: Equatable, Sendable {
    public let ownerName: String
    public let ownerTitle: String
    public let ownerImageName: String
    public let questTitle: String
    public let questDescription: String
    public let conditions: [QuestConditionDisplay]
    public let rewards: [QuestRewardDisplay]
    public let canComplete: Bool
}
