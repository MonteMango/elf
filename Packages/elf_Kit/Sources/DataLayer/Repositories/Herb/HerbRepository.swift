//
//  HerbRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public protocol HerbRepository: Sendable {
    /// Get a herb by its ID
    /// - Parameter id: Herb's unique identifier
    /// - Returns: Herb if found, nil otherwise
    func getHerb(id: HerbID) -> Herb?

    /// Get all available herbs
    /// - Returns: Array of all herbs
    func getAllHerbs() -> [Herb]

}
