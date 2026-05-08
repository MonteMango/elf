//
//  DungeonMapViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Drives the Map tab. Currently a thin shell over the dungeon graph; future
/// commits will add layout coordinates, room interaction, and (for splitPath /
/// randomPath) party-position tracking.
@MainActor
@Observable
public final class DungeonMapViewModel {

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.dungeonRepository) private var dungeonRepository

    // MARK: - Inputs

    private let dungeonId: UUID

    // MARK: - Initialization

    public init(dungeonId: UUID) {
        self.dungeonId = dungeonId
    }

    // MARK: - Derived

    public var dungeon: Dungeon? {
        dungeonRepository.getById(id: dungeonId)
    }
}
