//
//  ElfGameInitializationService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Dependencies
import Foundation

public final class ElfGameInitializationService: GameInitializationService {

    // MARK: - Dependencies (snapshotted at init)

    private let houseService: any HouseService
    private let elfInfoFactory: any ElfInfoFactory
    private let calendarService: any CalendarService
    private let gameRepository: any GameSaveStorage

    // MARK: - Initialization

    public init() {
        @Dependency(\.houseService) var houseService
        @Dependency(\.elfInfoFactory) var elfInfoFactory
        @Dependency(\.calendarService) var calendarService
        @Dependency(\.gameRepository) var gameRepository
        self.houseService = houseService
        self.elfInfoFactory = elfInfoFactory
        self.calendarService = calendarService
        self.gameRepository = gameRepository
    }

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
