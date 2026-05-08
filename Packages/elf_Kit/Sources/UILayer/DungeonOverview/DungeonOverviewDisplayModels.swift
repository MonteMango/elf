//
//  DungeonOverviewDisplayModels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Header

public struct DungeonHeaderDisplay: Equatable, Sendable {
    public let title: String
    public let regionSubtitle: String
    public let description: String

    public init(title: String, regionSubtitle: String, description: String) {
        self.title = title
        self.regionSubtitle = regionSubtitle
        self.description = description
    }
}

// MARK: - Monsters

public struct DungeonMonsterDisplay: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let imageName: String

    public init(id: UUID, title: String, imageName: String) {
        self.id = id
        self.title = title
        self.imageName = imageName
    }
}

// MARK: - Drops

public struct DungeonDropDisplay: Identifiable, Equatable, Sendable {
    public let id: String
    public let imageName: String
    public let tier: Int

    public init(id: String, imageName: String, tier: Int) {
        self.id = id
        self.imageName = imageName
        self.tier = tier
    }
}

// MARK: - Mini map preview

public enum DungeonNodeKind: Equatable, Sendable {
    case entrance
    case combat
    case miniBoss
    case event
    case boss
}

public struct DungeonRoomNodeDisplay: Identifiable, Equatable, Sendable {
    public let id: String
    public let kind: DungeonNodeKind

    public init(id: String, kind: DungeonNodeKind) {
        self.id = id
        self.kind = kind
    }
}
