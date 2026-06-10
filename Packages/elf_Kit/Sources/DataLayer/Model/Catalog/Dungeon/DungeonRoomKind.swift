//
//  DungeonRoomKind.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Sum-type describing what happens inside a dungeon room.
/// JSON shape:
///   `{ "type": "combat",   "monsters": [...] }`
///   `{ "type": "miniBoss", "monsters": [...] }`
///   `{ "type": "boss",     "monsters": [...] }`
///   `{ "type": "event",    "event": { ... } }`
public enum DungeonRoomKind: Codable, Sendable, Equatable, Hashable {
    case combat([MonsterRef])
    case miniBoss([MonsterRef])
    case boss([MonsterRef])
    case event(SpecialEvent)

    private enum CodingKeys: String, CodingKey {
        case type
        case monsters
        case event
    }

    private enum Discriminator: String, Codable {
        case combat
        case miniBoss
        case boss
        case event
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let discriminator = try container.decode(Discriminator.self, forKey: .type)
        switch discriminator {
        case .combat:
            let monsters = try container.decode([MonsterRef].self, forKey: .monsters)
            self = .combat(monsters)
        case .miniBoss:
            let monsters = try container.decode([MonsterRef].self, forKey: .monsters)
            self = .miniBoss(monsters)
        case .boss:
            let monsters = try container.decode([MonsterRef].self, forKey: .monsters)
            self = .boss(monsters)
        case .event:
            let event = try container.decode(SpecialEvent.self, forKey: .event)
            self = .event(event)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .combat(let monsters):
            try container.encode(Discriminator.combat, forKey: .type)
            try container.encode(monsters, forKey: .monsters)
        case .miniBoss(let monsters):
            try container.encode(Discriminator.miniBoss, forKey: .type)
            try container.encode(monsters, forKey: .monsters)
        case .boss(let monsters):
            try container.encode(Discriminator.boss, forKey: .type)
            try container.encode(monsters, forKey: .monsters)
        case .event(let event):
            try container.encode(Discriminator.event, forKey: .type)
            try container.encode(event, forKey: .event)
        }
    }

    /// Monsters in this room (empty for `.event`). Used by aggregators (drops, expected monsters).
    public var monsters: [MonsterRef] {
        switch self {
        case .combat(let m), .miniBoss(let m), .boss(let m): return m
        case .event: return []
        }
    }
}
