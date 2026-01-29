//
//  HouseService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Protocol for house creation and management
public protocol HouseService: Sendable {

    /// Create all 8 houses with player randomly assigned
    /// - Parameter playerElfInfo: Player's elf info
    /// - Returns: Tuple with houses array, player's house index, and player's member index
    func createAllHouses(
        playerElfInfo: ElfInfo
    ) async -> (houses: [House], playerHouseIndex: Int, playerMemberIndex: Int)
}
