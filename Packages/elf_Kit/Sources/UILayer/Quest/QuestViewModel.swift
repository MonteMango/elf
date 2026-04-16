//
//  QuestViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Display Data

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

public struct QuestDisplayData: Equatable, Sendable {
    public let ownerName: String
    public let ownerTitle: String
    public let ownerImageName: String
    public let questTitle: String
    public let questDescription: String
    public let conditions: [QuestConditionDisplay]
    public let rewards: [QuestRewardDisplay]
    public let canComplete: Bool
}

// MARK: - ViewModel

@MainActor
@Observable
public final class QuestViewModel {

    // MARK: - Dependencies

    private let questId: QuestID
    private let gameService: any GameService
    private let questRepository: any QuestRepository
    private let materialRepository: any Repository<Material>
    private let oreRepository: any Repository<Ore>
    private let herbRepository: any Repository<Herb>
    private let monsterRepository: any MonsterRepository

    // MARK: - Display Data (derived reactively from repositories)

    public var questData: QuestDisplayData? {
        guard let quest = questRepository.getById(id: questId) else { return nil }
        guard let character = questRepository.character(by: quest.questOwnerId) else { return nil }

        return QuestDisplayData(
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

    public init(
        questId: QuestID,
        gameService: any GameService,
        questRepository: any QuestRepository,
        materialRepository: any Repository<Material>,
        oreRepository: any Repository<Ore>,
        herbRepository: any Repository<Herb>,
        monsterRepository: any MonsterRepository
    ) {
        self.questId = questId
        self.gameService = gameService
        self.questRepository = questRepository
        self.materialRepository = materialRepository
        self.oreRepository = oreRepository
        self.herbRepository = herbRepository
        self.monsterRepository = monsterRepository
    }

    // MARK: - Actions

    public func advanceToNextDay() async {
        gameService.advanceToNextDay()
        try? await gameService.saveGame()
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
