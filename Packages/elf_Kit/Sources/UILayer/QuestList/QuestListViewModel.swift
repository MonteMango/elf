//
//  QuestListViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Display Data

public struct QuestOwnerDisplay: Identifiable, Equatable, Sendable {
    public let id: QuestCharacterID
    public let questId: QuestID
    public let name: String
    public let title: String
    public let imageName: String
    public let questTitle: String
    public let rewardText: String
}

// MARK: - ViewModel

@MainActor
@Observable
public final class QuestListViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService
    private let questRepository: any QuestRepository
    private let materialRepository: any Repository<Material>

    // MARK: - Game Session State (exposed for top bar / calendar nav)

    public var currentDay: GameDay { gameService.currentDay }
    public var upcomingDays: [GameDay] { gameService.upcomingDays }
    public var calendar: [GameDay] { gameService.calendar }
    public var actionPoints: ActionPoints { gameService.actionPoints }
    public var isLastDay: Bool { gameService.isLastDay }

    // MARK: - Display Data (derived reactively from repositories)

    public var questOwners: [QuestOwnerDisplay] {
        questRepository.allCharacters().compactMap { character in
            guard let quest = questRepository.quests(for: character.id).first else { return nil }
            return QuestOwnerDisplay(
                id: character.id,
                questId: quest.id,
                name: character.name,
                title: character.title,
                imageName: character.imageName,
                questTitle: quest.title,
                rewardText: formatReward(quest.rewards)
            )
        }
    }

    // MARK: - Initialization

    public init(
        gameService: any GameService,
        questRepository: any QuestRepository,
        materialRepository: any Repository<Material>
    ) {
        self.gameService = gameService
        self.questRepository = questRepository
        self.materialRepository = materialRepository
    }

    // MARK: - Actions

    public func advanceToNextDay() async {
        gameService.advanceToNextDay()
        try? await gameService.saveGame()
    }

    // MARK: - Private

    private func formatReward(_ rewards: [QuestReward]) -> String {
        rewards.map { reward in
            switch reward {
            case .item(let itemId, let amount):
                let name = materialRepository.getById(id: itemId)?.title ?? "Unknown"
                return "\(amount)x \(name)"
            }
        }.joined(separator: ", ")
    }
}
