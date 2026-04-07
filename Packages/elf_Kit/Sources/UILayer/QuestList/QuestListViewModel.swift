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

    // MARK: - Game State

    private var game: Game

    // MARK: - Display Data

    public var questOwners: [QuestOwnerDisplay] = []

    // MARK: - Computed Properties (ScreenTopBar)

    public var currentActionPoints: Int {
        game.gameState.currentActionPoints
    }

    public var maxActionPoints: Int {
        game.gameState.maxActionPoints
    }

    public var isLastDay: Bool {
        game.gameState.isLastDay
    }

    public var currentDay: GameDay {
        game.gameState.currentDay
    }

    public var upcomingDays: [GameDay] {
        game.gameState.upcomingDays
    }

    public var calendar: [GameDay] {
        game.gameState.calendar
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
        self.game = gameService.currentGame
    }

    // MARK: - Game State Observation

    public func observeGameState() async {
        self.game = gameService.currentGame
        await loadQuestOwners()
        for await game in await gameService.gameUpdates() {
            self.game = game
        }
    }

    // MARK: - Actions

    public func onQuestOwnerTapped(_ title: String) {
        print("Quest owner tapped: \(title)")
    }

    public func advanceToNextDay() async {
        await gameService.advanceToNextDay()
        try? await gameService.saveGame()
    }

    // MARK: - Private

    private func loadQuestOwners() async {
        let characters = await questRepository.allCharacters()
        var displays: [QuestOwnerDisplay] = []

        for character in characters {
            let quests = await questRepository.quests(for: character.id)
            guard let quest = quests.first else { continue }

            let rewardText = await formatReward(quest.rewards)

            displays.append(QuestOwnerDisplay(
                id: character.id,
                name: character.name,
                title: character.title,
                imageName: character.imageName,
                questTitle: quest.title,
                rewardText: rewardText
            ))
        }

        self.questOwners = displays
    }

    private func formatReward(_ rewards: [QuestReward]) async -> String {
        var parts: [String] = []
        for reward in rewards {
            switch reward {
            case .item(let itemId, let amount):
                let material = await materialRepository.getById(id: itemId)
                let name = material?.title ?? "Unknown"
                parts.append("\(amount)x \(name)")
            }
        }
        return parts.joined(separator: ", ")
    }
}
