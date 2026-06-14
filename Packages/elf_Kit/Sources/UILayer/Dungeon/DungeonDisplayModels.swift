//
//  DungeonDisplayModels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Tabs

public enum DungeonTab: String, CaseIterable, Sendable {
    case overview
    case squad
    case map

    public var title: String {
        switch self {
        case .overview: return "Overview"
        case .squad: return "Squad"
        case .map: return "Map"
        }
    }
}

// MARK: - Transition

/// Describes the in-flight dungeon transition shown by the full-screen overlay.
/// Sum-type so impossible states are unrepresentable: it is either entering the
/// dungeon or moving between two specific rooms.
public enum DungeonTransition: Equatable, Sendable {
    case enteringDungeon(name: String)
    case movingBetweenRooms(from: String, to: String)
    /// Resolving a non-combat room event (e.g. drinking at a healing spring).
    /// Title/subtitle are supplied by the caller so each event can describe
    /// itself.
    case resolvingEvent(title: String, subtitle: String)

    public var title: String {
        switch self {
        case .enteringDungeon: return "Entering Dungeon"
        case .movingBetweenRooms: return "Traveling"
        case .resolvingEvent(let title, _): return title
        }
    }

    public var subtitle: String {
        switch self {
        case .enteringDungeon(let name): return name
        case .movingBetweenRooms(let from, let to): return "\(from) → \(to)"
        case .resolvingEvent(_, let subtitle): return subtitle
        }
    }
}

// MARK: - Squad

/// Shared squad member display: used by the Overview tab as a compact preview
/// list and by the Squad tab as the source of truth for the full detail layout.
public struct DungeonSquadMemberDisplay: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let imageName: String
    public let level: Int
    public let currentHP: Int
    public let maxHP: Int
    public let isHero: Bool

    public init(
        id: UUID,
        name: String,
        imageName: String,
        level: Int,
        currentHP: Int,
        maxHP: Int,
        isHero: Bool
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.level = level
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.isHero = isHero
    }

    public var hpProgress: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }
}

// MARK: - Squad detail (Squad tab)

/// Full per-elf state for the Squad tab cell — distinct from the compact
/// `DungeonSquadMemberDisplay` used by the Overview rail.
public struct DungeonSquadMemberDetail: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let imageName: String
    public let level: Int
    public let currentHP: Int
    public let maxHP: Int
    public let currentMP: Int
    public let maxMP: Int
    public let attributes: HeroAttributes
    public let equippedItems: [HeroItemType: HeroEquippedSlot]
    public let activeBuffs: [String]
    public let state: State
    public let isHero: Bool

    public enum State: Sendable, Equatable, CaseIterable {
        case alive
        case dead
        case escaped
    }

    public init(
        id: UUID,
        name: String,
        imageName: String,
        level: Int,
        currentHP: Int,
        maxHP: Int,
        currentMP: Int,
        maxMP: Int,
        attributes: HeroAttributes,
        equippedItems: [HeroItemType: HeroEquippedSlot],
        activeBuffs: [String],
        state: State,
        isHero: Bool
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.level = level
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.currentMP = currentMP
        self.maxMP = maxMP
        self.attributes = attributes
        self.equippedItems = equippedItems
        self.activeBuffs = activeBuffs
        self.state = state
        self.isHero = isHero
    }

    public var hpProgress: Double {
        guard maxHP > 0 else { return 0 }
        return Double(currentHP) / Double(maxHP)
    }

    public var mpProgress: Double {
        guard maxMP > 0 else { return 0 }
        return Double(currentMP) / Double(maxMP)
    }
}
