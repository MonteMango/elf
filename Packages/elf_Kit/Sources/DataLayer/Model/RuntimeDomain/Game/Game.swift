//
//  Game.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Foundation

/// Root game state structure
/// Contains 8 houses with 10 elves each, and game state (day, action points, etc.)
public struct Game: Sendable, Equatable {

    // MARK: - Constants

    public static let housesCount = 8

    // MARK: - Properties

    /// Unique game identifier
    public let id: GameID

    /// All houses in the tournament (exactly 8)
    public var houses: [House]

    /// Current game state (day, action points, upcoming days)
    public var gameState: GameState

    /// Index of the house where player belongs (0-7)
    public var playerHouseIndex: Int

    /// Index of the player within the house members (0-9)
    public var playerMemberIndex: Int

    // MARK: - O(1) Computed Properties

    /// Player's elf info (O(1) access)
    public var player: ElfInfo {
        houses[playerHouseIndex].members[playerMemberIndex]
    }

    /// Player's house (O(1) access)
    public var playerHouse: House {
        houses[playerHouseIndex]
    }

    // MARK: - Initialization

    public init(
        id: GameID = GameID(),
        houses: [House],
        gameState: GameState,
        playerHouseIndex: Int,
        playerMemberIndex: Int
    ) {
        precondition(houses.count == Game.housesCount, "Game must have exactly \(Game.housesCount) houses")
        precondition(playerHouseIndex >= 0 && playerHouseIndex < Game.housesCount, "Invalid playerHouseIndex")
        precondition(playerMemberIndex >= 0 && playerMemberIndex < House.membersCount, "Invalid playerMemberIndex")

        self.id = id
        self.houses = houses
        self.gameState = gameState
        self.playerHouseIndex = playerHouseIndex
        self.playerMemberIndex = playerMemberIndex
    }
}
