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
    /// Looks up in materials first, then in fish repository if not found
    /// - Parameter id: Material's unique identifier
    /// - Returns: Material if found, nil otherwise
    func getMaterial(id: UUID) -> Material?

    /// Get material category by ID
    /// - Parameter id: Material's unique identifier
    /// - Returns: MaterialSubcategory if found, nil otherwise
    func getMaterialCategory(id: UUID) -> MaterialSubcategory?
}
