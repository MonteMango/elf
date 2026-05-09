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

    // MARK: - Dependencies (snapshotted at init)

    private let session: GameSession
    private let questRepository: any QuestRepository
    private let materialRepository: any Repository<Material>

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

    public init(session: GameSession) {
        @Dependency(\.questRepository) var questRepository
        @Dependency(\.materialRepository) var materialRepository
        self.questRepository = questRepository
        self.materialRepository = materialRepository

        self.session = session
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
