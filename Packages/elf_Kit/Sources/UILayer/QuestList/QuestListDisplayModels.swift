//
//  QuestListDisplayModels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct QuestOwnerDisplay: Identifiable, Equatable, Sendable {
    public let id: QuestCharacterID
    public let questId: QuestID
    public let name: String
    public let title: String
    public let imageName: String
    public let questTitle: String
    public let rewardText: String
}
