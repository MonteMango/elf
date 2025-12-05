//
//  GameSave.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

// MARK: - GameSave (Root DTO)

/// Data Transfer Object for game persistence
/// Wraps game data with versioning, timestamps, and integrity checksum
public struct GameSave: Codable, Sendable {

    // MARK: - Version

    /// Current save format version
    public static let currentVersion = 1

    // MARK: - Properties

    /// Save format version for migration support
    public let version: Int

    /// When this save was created
    public let savedAt: Date

    /// App version that created this save
    public let appVersion: String

    /// Total play time in seconds
    public let playTime: TimeInterval

    /// The actual game data
    public let data: GameSaveData

    // MARK: - Initialization

    /// Create a new GameSave from a Game object
    public init(from game: Game, playTime: TimeInterval, appVersion: String) {
        self.version = Self.currentVersion
        self.savedAt = Date()
        self.appVersion = appVersion
        self.playTime = playTime
        self.data = GameSaveData(from: game)
    }

    // MARK: - Conversion

    /// Convert back to Game domain model
    public func toGame() throws -> Game {
        try data.toGame()
    }
}

// MARK: - GameSaveData

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

    public func toGame() throws -> Game {
        let houses = self.houses.map { $0.toHouse() }
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

// MARK: - HouseSaveData

public struct HouseSaveData: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let logoImageName: String
    public let isEliminated: Bool
    public let members: [ElfSaveData]

    public init(from house: House) {
        self.id = house.id
        self.name = house.name
        self.logoImageName = house.logoImageName
        self.isEliminated = house.isEliminated
        self.members = house.members.map { ElfSaveData(from: $0) }
    }

    public func toHouse() -> House {
        House(
            id: id,
            name: name,
            logoImageName: logoImageName,
            isEliminated: isEliminated,
            members: members.map { $0.toElfInfo() }
        )
    }
}

// MARK: - ElfSaveData

public struct ElfSaveData: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let imageName: String
    public let fightStyle: FightStyle
    public let level: Int16
    public let currentExp: Int
    public let expToNextLevel: Int
    public let fightStyleAttributes: HeroAttributes
    public let randomLevelAttributes: HeroAttributes
    public let currentHP: Int16
    public let currentMP: Int16
    public let equippedItems: [HeroItemType: UUID]
    public let reputation: Int

    public init(from elf: ElfInfo) {
        self.id = elf.id
        self.name = elf.name
        self.imageName = elf.imageName
        self.fightStyle = elf.fightStyle
        self.level = elf.level
        self.currentExp = elf.currentExp
        self.expToNextLevel = elf.expToNextLevel
        self.fightStyleAttributes = elf.fightStyleAttributes
        self.randomLevelAttributes = elf.randomLevelAttributes
        self.currentHP = elf.currentHP
        self.currentMP = elf.currentMP
        self.equippedItems = elf.equippedItems
        self.reputation = elf.reputation
    }

    public func toElfInfo() -> ElfInfo {
        ElfInfo(
            id: id,
            name: name,
            imageName: imageName,
            fightStyle: fightStyle,
            level: level,
            currentExp: currentExp,
            expToNextLevel: expToNextLevel,
            fightStyleAttributes: fightStyleAttributes,
            randomLevelAttributes: randomLevelAttributes,
            currentHP: currentHP,
            currentMP: currentMP,
            equippedItems: equippedItems,
            reputation: reputation
        )
    }
}

// MARK: - GameStateSaveData

public struct GameStateSaveData: Codable, Sendable {
    public let currentDay: GameDaySaveData
    public let currentActionPoints: Int
    public let maxActionPoints: Int
    public let upcomingDays: [GameDaySaveData]

    public init(from gameState: GameState) {
        self.currentDay = GameDaySaveData(from: gameState.currentDay)
        self.currentActionPoints = gameState.currentActionPoints
        self.maxActionPoints = gameState.maxActionPoints
        self.upcomingDays = gameState.upcomingDays.map { GameDaySaveData(from: $0) }
    }

    public func toGameState() -> GameState {
        GameState(
            currentDay: currentDay.toGameDay(),
            currentActionPoints: currentActionPoints,
            maxActionPoints: maxActionPoints,
            upcomingDays: upcomingDays.map { $0.toGameDay() }
        )
    }
}

// MARK: - GameDaySaveData

public struct GameDaySaveData: Codable, Sendable {
    public let id: UUID
    public let dayNumber: Int
    public let dayType: DayType

    public init(from gameDay: GameDay) {
        self.id = gameDay.id
        self.dayNumber = gameDay.dayNumber
        self.dayType = gameDay.dayType
    }

    public func toGameDay() -> GameDay {
        GameDay(
            id: id,
            dayNumber: dayNumber,
            dayType: dayType
        )
    }
}
