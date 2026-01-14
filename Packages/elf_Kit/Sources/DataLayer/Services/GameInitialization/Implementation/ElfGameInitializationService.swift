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
    private let gameRepository: GameRepository?

    // MARK: - Initialization

    public init(
        houseService: HouseService,
        elfInfoFactory: ElfInfoFactory,
        calendarService: CalendarService,
        gameRepository: GameRepository? = nil
    ) {
        self.houseService = houseService
        self.elfInfoFactory = elfInfoFactory
        self.calendarService = calendarService
        self.gameRepository = gameRepository
    }

    // MARK: - GameInitializationService

    public func createNewGame(
        playerCharacter: PlayerCharacter,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes
    ) async throws -> Game {
        // Create ElfInfo from player character
        let playerElfInfo = elfInfoFactory.create(from: playerCharacter)

        // Create all houses with the player assigned to one of them
        let (houses, houseIndex, memberIndex) = await houseService.createAllHouses(
            playerElfInfo: playerElfInfo
        )

        // Generate full calendar
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
        if let repository = gameRepository {
            do {
                try await repository.save(game, slotId: SaveSlotInfo.defaultSlotId, playTime: 0)
            } catch {
                throw GameInitializationError.failedToSaveGame(error)
            }
        }

        return game
    }
}

// MARK: - Sendable Conformance
// Thread-safe: All stored properties are immutable (let) after initialization.
// All dependencies are Sendable protocols: HouseService, ElfInfoFactory, CalendarService, GameRepository.
extension ElfGameInitializationService: @unchecked Sendable {}
