//
//  HouseService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Protocol for house creation and management
public protocol HouseService: Sendable {

    /// Available house templates (name + logo)
    var templates: [HouseTemplate] { get }

    /// Create a house with AI elves only
    /// - Parameters:
    ///   - templateIndex: Index of the house template (0-7)
    ///   - level: Level for AI elves
    /// - Returns: House with 10 AI elves
    func createHouse(templateIndex: Int, level: Int16) async -> House

    /// Create a house with player and AI elves
    /// - Parameters:
    ///   - templateIndex: Index of the house template (0-7)
    ///   - level: Level for AI elves
    ///   - playerElfInfo: Player's elf info
    ///   - playerMemberIndex: Position for player in the house (0-9)
    /// - Returns: House with player and 9 AI elves
    func createHouse(
        templateIndex: Int,
        level: Int16,
        playerElfInfo: ElfInfo,
        playerMemberIndex: Int
    ) async -> House

    /// Create all 8 houses with player randomly assigned
    /// - Parameter playerElfInfo: Player's elf info
    /// - Returns: Tuple with houses array, player's house index, and player's member index
    func createAllHouses(
        playerElfInfo: ElfInfo
    ) async -> (houses: [House], playerHouseIndex: Int, playerMemberIndex: Int)
}
