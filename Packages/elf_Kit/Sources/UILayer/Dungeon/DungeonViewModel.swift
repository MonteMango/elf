//
//  DungeonViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Parent VM for the dungeon briefing screen. Owns only what the parent shell
/// needs: tab routing, the dungeon background image, and the entrance gate.
/// Each tab (Overview / Squad / Map) has its own VM and resolves its own data
/// independently from `dungeonId` + `allyIds`.
@MainActor
@Observable
public final class DungeonViewModel {

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.dungeonRepository) private var dungeonRepository

    private let gameService: any GameService

    // MARK: - Inputs (stable for the lifetime of this run)

    public let dungeonId: UUID
    public let allyIds: [UUID]

    // MARK: - View state

    public var activeTab: DungeonTab = .overview

    // MARK: - Initialization

    public init(gameService: any GameService, dungeonId: UUID, allyIds: [UUID]) {
        self.gameService = gameService
        self.dungeonId = dungeonId
        self.allyIds = allyIds
    }

    // MARK: - Derived

    public var dungeon: Dungeon? {
        dungeonRepository.getById(id: dungeonId)
    }

    public var backgroundImageName: String {
        dungeon?.backgroundImageName ?? ""
    }

    /// MVP: Entrance is enabled. The view currently pops back; the real
    /// dungeon-run flow lands in a follow-up PR.
    public var canEnter: Bool { true }
}
