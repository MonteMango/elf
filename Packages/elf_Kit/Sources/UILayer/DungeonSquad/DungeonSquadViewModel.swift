//
//  DungeonSquadViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Drives the Squad tab. Currently returns the same shared squad data the
/// Overview-tab preview uses; future commits will add per-elf detail (full
/// stats, equipment, alive/dead flags during a run).
@MainActor
@Observable
public final class DungeonSquadViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService

    @ObservationIgnored
    @Dependency(\.progressionService) private var progressionService

    // MARK: - Inputs

    private let dungeonId: UUID
    private let allyIds: [UUID]

    // MARK: - Initialization

    public init(gameService: any GameService, dungeonId: UUID, allyIds: [UUID]) {
        self.gameService = gameService
        self.dungeonId = dungeonId
        self.allyIds = allyIds
    }

    // MARK: - Derived

    public var squad: [DungeonSquadMemberDisplay] {
        let player = gameService.player
        var rows: [DungeonSquadMemberDisplay] = [
            DungeonSquadMemberDisplay(
                id: player.id,
                name: player.name,
                imageName: player.imageName,
                level: progressionService.calculateLevel(currentExp: player.currentExp),
                currentHP: Int(player.currentHP),
                maxHP: Int(player.maxHP),
                isHero: true
            )
        ]

        let house = gameService.houses[gameService.playerHouseIndex]
        let elfById = Dictionary(uniqueKeysWithValues: house.members.map { ($0.id, $0) })
        for id in allyIds {
            guard let elf = elfById[id] else { continue }
            rows.append(DungeonSquadMemberDisplay(
                id: elf.id,
                name: elf.name,
                imageName: elf.imageName,
                level: progressionService.calculateLevel(currentExp: elf.currentExp),
                currentHP: Int(elf.currentHP),
                maxHP: Int(elf.maxHP),
                isHero: false
            ))
        }
        return rows
    }
}
