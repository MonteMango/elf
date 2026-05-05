//
//  DayType.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation

/// Types of game days with different activities
public enum DayType: Int, CaseIterable, Sendable, Codable {
    case normal = 0
    case dungeon = 1
    case randomEvent = 2
    case houseWar = 3
    case unknown = 4

    /// Display name for the day type
    public var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .dungeon: return "Dungeon"
        case .randomEvent: return "Event"
        case .houseWar: return "War"
        case .unknown: return "?"
        }
    }

    /// Symbol to display instead of day number (only for unknown type)
    public var displaySymbol: String? {
        self == .unknown ? "?" : nil
    }

    /// Actions available to the player on this day type.
    public var availableActions: [ActionType] {
        switch self {
        case .normal:       [.farm, .hunt, .quests, .craft]
        case .dungeon:      [.dungeon]
        case .randomEvent,
             .houseWar,
             .unknown:      []
        }
    }
}
