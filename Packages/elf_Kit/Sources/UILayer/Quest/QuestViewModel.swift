//
//  QuestViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class QuestViewModel {

    // MARK: - Dependencies

    private let questId: QuestID
    private let gameService: any GameService

    @ObservationIgnored
    @Dependency(\.questRepository) private var questRepository

    @ObservationIgnored
    @Dependency(\.materialRepository) private var materialRepository

    @ObservationIgnored
    @Dependency(\.oreRepository) private var oreRepository

    @ObservationIgnored
    @Dependency(\.herbRepository) private var herbRepository

    @ObservationIgnored
    @Dependency(\.monsterRepository) private var monsterRepository

    // MARK: - Display Data (derived reactively from repositories)

    public var questData: QuestDisplay? {
        guard let quest = questRepository.getById(id: questId) else { return nil }
        guard let character = questRepository.character(by: quest.questOwnerId) else { return nil }

        return QuestDisplay(
            ownerName: character.name,
            ownerTitle: character.title,
            ownerImageName: character.imageName,
            questTitle: quest.title,
            questDescription: quest.description,
            conditions: formatConditions(quest.conditions),
            rewards: formatRewards(quest.rewards),
            canComplete: false
        )
    }

    // MARK: - Initialization

    public init(questId: QuestID, gameService: any GameService) {
        self.questId = questId
        self.gameService = gameService
    }

    // MARK: - Private

    private func formatConditions(_ questConditions: [QuestCondition]) -> [QuestConditionDisplay] {
        questConditions.enumerated().map { index, condition in
            switch condition {
            case .bringItem(let itemId, let amount):
                let itemInfo = lookupItem(by: itemId)
                return QuestConditionDisplay(
                    id: "\(index)_\(itemId)",
                    imageName: itemInfo.imageName,
                    amount: amount,
                    text: itemInfo.title
                )

            case .killMonster(let monsterId, let amount):
                let monster = monsterRepository.getById(id: monsterId)
                return QuestConditionDisplay(
                    id: "\(index)_\(monsterId)",
                    imageName: monster?.imageName ?? "",
                    amount: amount,
                    text: monster?.title ?? "Unknown"
                )
            }
        }
    }

    private func formatRewards(_ questRewards: [QuestReward]) -> [QuestRewardDisplay] {
        questRewards.enumerated().map { index, reward in
            switch reward {
            case .item(let itemId, let amount):
                let itemInfo = lookupItem(by: itemId)
                return QuestRewardDisplay(
                    id: "\(index)_\(itemId)",
                    imageName: itemInfo.imageName,
                    quantity: amount
                )
            }
        }
    }

    /// Looks up an item across all repositories (materials, ores, herbs) by UUID.
    private func lookupItem(by itemId: UUID) -> (title: String, imageName: String) {
        if let material = materialRepository.getById(id: itemId) {
            return (material.title, material.imageName)
        }
        if let ore = oreRepository.getById(id: OreID(rawValue: itemId)) {
            return (ore.title, ore.imageName)
        }
        if let herb = herbRepository.getById(id: HerbID(rawValue: itemId)) {
            return (herb.title, herb.imageName)
        }
        return ("Unknown", "")
    }
}
