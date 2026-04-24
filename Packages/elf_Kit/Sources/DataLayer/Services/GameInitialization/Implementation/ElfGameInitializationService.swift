//
//  ElfGameInitializationService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Dependencies
import Foundation

public final class ElfGameInitializationService: GameInitializationService {

    // MARK: - Dependencies

    @Dependency(\.houseService) private var houseService
    @Dependency(\.elfInfoFactory) private var elfInfoFactory
    @Dependency(\.calendarService) private var calendarService
    @Dependency(\.gameRepository) private var gameRepository

    // MARK: - Initialization

    public init() {}

    // MARK: - GameInitializationService

    public func createNewGame(
        playerCharacter: PlayerCharacter
    ) async throws -> Game {
        let playerElfInfo = elfInfoFactory.create(from: playerCharacter)

        let (houses, houseIndex, memberIndex) = await houseService.createAllHouses(
            playerElfInfo: playerElfInfo
        )

        let calendar = calendarService.generateFullCalendar()
        let firstDay = calendar.first ?? GameDay(dayNumber: 1, dayType: .normal)

        // Create game state with full action points
        let gameState = GameState(
            currentDay: firstDay,
            actionPoints: ActionPoints.unsafeCreate(current: 100, maximum: 100),
            calendar: calendar
        )

        // Create game
        let game = Game(
            houses: houses,
            gameState: gameState,
            playerHouseIndex: houseIndex,
            playerMemberIndex: memberIndex
        )

        // Auto-save new game
        do {
            try await gameRepository.save(game, slotId: SaveSlotInfo.defaultSlotId, playTime: 0)
        } catch {
            throw GameInitializationError.failedToSaveGame(error)
        }

        return game
    }
}
