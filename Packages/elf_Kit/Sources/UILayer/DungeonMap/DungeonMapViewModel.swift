//
//  DungeonMapViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Drives the Map tab. Currently a thin shell over the dungeon graph; future
/// commits will add layout coordinates, room interaction, and (for splitPath /
/// randomPath) party-position tracking.
@MainActor
@Observable
public final class DungeonMapViewModel {

    private let session: DungeonSession

    public init(session: DungeonSession) {
        self.session = session
    }

    public var dungeon: Dungeon? { session.dungeon }
}
