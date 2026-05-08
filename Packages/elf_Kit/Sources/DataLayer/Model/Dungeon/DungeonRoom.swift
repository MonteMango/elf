//
//  DungeonRoom.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// A single node in a dungeon graph. Connections to next rooms are explicit
/// (`nextRoomIds`) — empty array marks the final room.
public struct DungeonRoom: Codable, Sendable, Identifiable, Equatable, Hashable {
    public let id: UUID
    public let title: String
    public let description: String?
    /// Used only by `randomPath` dungeons; `nil` or `0` for `onePath`/`splitPath`.
    public let stage: Int?
    public let kind: DungeonRoomKind
    public let nextRoomIds: [UUID]

    public init(
        id: UUID,
        title: String,
        description: String? = nil,
        stage: Int? = nil,
        kind: DungeonRoomKind,
        nextRoomIds: [UUID]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.stage = stage
        self.kind = kind
        self.nextRoomIds = nextRoomIds
    }
}
