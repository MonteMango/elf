//
//  QuestReward.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Describes what the player receives upon completing a quest.
/// Each case carries only the parameters relevant to that reward type.
public enum QuestReward: Sendable, Hashable {
    case item(itemId: UUID, amount: Int)
}

// MARK: - Codable

extension QuestReward: Codable {

    private enum RewardType: String, Codable {
        case item
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case itemId
        case amount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(RewardType.self, forKey: .type)

        switch type {
        case .item:
            let itemId = try container.decode(UUID.self, forKey: .itemId)
            let amount = try container.decode(Int.self, forKey: .amount)
            self = .item(itemId: itemId, amount: amount)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .item(let itemId, let amount):
            try container.encode(RewardType.item, forKey: .type)
            try container.encode(itemId, forKey: .itemId)
            try container.encode(amount, forKey: .amount)
        }
    }
}
