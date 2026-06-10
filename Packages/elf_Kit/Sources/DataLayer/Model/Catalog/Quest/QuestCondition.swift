//
//  QuestCondition.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Describes what the player must do to complete a quest.
/// Each case carries only the parameters relevant to that condition type.
public enum QuestCondition: Sendable, Hashable {
    case bringItem(itemId: UUID, amount: Int)
    case killMonster(monsterId: UUID, amount: Int)
}

// MARK: - Codable

extension QuestCondition: Codable {

    private enum ConditionType: String, Codable {
        case bringItem
        case killMonster
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case itemId
        case monsterId
        case amount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ConditionType.self, forKey: .type)

        switch type {
        case .bringItem:
            let itemId = try container.decode(UUID.self, forKey: .itemId)
            let amount = try container.decode(Int.self, forKey: .amount)
            self = .bringItem(itemId: itemId, amount: amount)

        case .killMonster:
            let monsterId = try container.decode(UUID.self, forKey: .monsterId)
            let amount = try container.decode(Int.self, forKey: .amount)
            self = .killMonster(monsterId: monsterId, amount: amount)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .bringItem(let itemId, let amount):
            try container.encode(ConditionType.bringItem, forKey: .type)
            try container.encode(itemId, forKey: .itemId)
            try container.encode(amount, forKey: .amount)

        case .killMonster(let monsterId, let amount):
            try container.encode(ConditionType.killMonster, forKey: .type)
            try container.encode(monsterId, forKey: .monsterId)
            try container.encode(amount, forKey: .amount)
        }
    }
}
