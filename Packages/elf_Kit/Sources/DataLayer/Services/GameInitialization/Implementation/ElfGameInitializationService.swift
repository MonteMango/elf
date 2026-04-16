//
//  ElfGameInitializationService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

public final class ElfGameInitializationService: GameInitializationService {

    // MARK: - Dependencies

    private let houseService: HouseService
    private let elfInfoFactory: ElfInfoFactory
    private let calendarService: CalendarService
    private let gameRepository: GameSaveStorage

    // MARK: - Initialization

    public init(
        houseService: HouseService,
        elfInfoFactory: ElfInfoFactory,
        calendarService: CalendarService,
        gameRepository: GameSaveStorage
    ) {
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
