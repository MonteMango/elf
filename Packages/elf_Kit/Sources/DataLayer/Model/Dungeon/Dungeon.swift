//
//  Dungeon.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Static dungeon definition loaded from `Dungeons.json`. Per-run state
/// (alive members, current room) lives separately and references this by `id`.
public struct Dungeon: Codable, Sendable, Identifiable, Equatable, Hashable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: DungeonType
    public let world: WorldType
    public let backgroundImageName: String
    /// Entry rooms. `onePath`/`splitPath`: one entry. `randomPath`: 16 stage-1 rooms.
    public let entryRoomIds: [UUID]
    public let rooms: [DungeonRoom]

    public init(
        id: UUID,
        title: String,
        description: String,
        type: DungeonType,
        world: WorldType,
        backgroundImageName: String,
        entryRoomIds: [UUID],
        rooms: [DungeonRoom]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.world = world
        self.backgroundImageName = backgroundImageName
        self.entryRoomIds = entryRoomIds
        self.rooms = rooms
    }

    public func room(id: UUID) -> DungeonRoom? {
        rooms.first { $0.id == id }
    }
}

/// Top-level wrapper for `Dungeons.json`, mirroring `MonstersData` / `RecipesData`.
public struct DungeonsData: Codable, Sendable {
    public let version: String
    public let dungeons: [Dungeon]

    public init(version: String, dungeons: [Dungeon]) {
        self.version = version
        self.dungeons = dungeons
    }

    public static func empty() -> DungeonsData {
        DungeonsData(version: "1.0-empty", dungeons: [])
    }
}
