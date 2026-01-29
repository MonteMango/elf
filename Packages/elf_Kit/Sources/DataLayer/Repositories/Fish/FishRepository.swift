//
//  FishRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import Foundation

public protocol FishRepository: Sendable {
    /// Get a fish by its ID
    /// - Parameter id: Fish's unique identifier
    /// - Returns: Fish if found, nil otherwise
    func getFish(id: FishID) -> Fish?

    /// Get all available fish
    /// - Returns: Array of all fish
    func getAllFish() -> [Fish]

}
