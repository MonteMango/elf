//
//  GameSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

/// Core game data without metadata
public struct GameSaveData: Codable, Sendable {
    public let gameId: UUID
    public let houses: [HouseSaveData]
    public let gameState: GameStateSaveData
    public let playerHouseIndex: Int
    public let playerMemberIndex: Int

    public init(from game: Game) {
        self.gameId = game.id
        self.houses = game.houses.map { HouseSaveData(from: $0) }
        self.gameState = GameStateSaveData(from: game.gameState)
        self.playerHouseIndex = game.playerHouseIndex
        self.playerMemberIndex = game.playerMemberIndex
    }

    public func toGame(
        itemsRepository: ItemsRepository,
        inventoryService: InventoryService
    ) throws -> Game {
        var houses: [House] = []
        for houseSaveData in self.houses {
            let house = try houseSaveData.toHouse(
                itemsRepository: itemsRepository,
                inventoryService: inventoryService
            )
            houses.append(house)
        }
        let gameState = self.gameState.toGameState()

        return Game(
            id: gameId,
            houses: houses,
            gameState: gameState,
            playerHouseIndex: playerHouseIndex,
            playerMemberIndex: playerMemberIndex
        )
    }
}
