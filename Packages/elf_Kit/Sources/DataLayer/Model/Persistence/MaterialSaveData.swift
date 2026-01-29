//
//  MaterialSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// DTO for material persistence.
/// Materials are stackable, so we store ID and quantity.
public struct MaterialSaveData: Sendable, Equatable, Codable {
    /// Material ID from MaterialsData
    public let id: UUID

    /// Quantity of this material (stackable)
    public let quantity: Int

    /// Create from InventoryMaterial
    public init(from material: InventoryMaterial) {
        self.id = material.id
        self.quantity = material.quantity
    }
}
