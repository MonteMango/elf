//
//  QuestListViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class QuestListViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService

    @ObservationIgnored
    @Dependency(\.questRepository) private var questRepository

    @ObservationIgnored
    @Dependency(\.materialRepository) private var materialRepository

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

    public init(gameService: any GameService) {
        self.gameService = gameService
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
