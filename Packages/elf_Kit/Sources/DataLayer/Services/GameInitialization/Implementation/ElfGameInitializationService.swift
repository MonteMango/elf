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
        // Create ElfInfo from player character
        let playerElfInfo = await elfInfoFactory.create(from: playerCharacter)

        // Create all houses with the player assigned to one of them
        let (houses, houseIndex, memberIndex) = await houseService.createAllHouses(
            playerElfInfo: playerElfInfo
        )

        // Generate full calendar
        let calendar = await calendarService.generateFullCalendar()
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