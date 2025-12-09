//
//  MaterialRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

public protocol MaterialRepository: Sendable {
    /// All loaded materials data
    var materialsData: MaterialsData { get }

    /// Get a material by its ID
    /// - Parameter id: Material's unique identifier
    /// - Returns: Material if found, nil otherwise
    func getMaterial(id: UUID) -> Material?
}
