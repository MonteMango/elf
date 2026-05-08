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
