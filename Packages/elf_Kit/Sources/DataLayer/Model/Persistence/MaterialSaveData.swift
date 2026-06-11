//
//  MaterialSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// DTO for material persistence.
/// Materials are stackable, so we store the typed `MaterialRef` (which carries
/// source + id) and the quantity.
public struct MaterialSaveData: Sendable, Equatable, Codable {
    /// Type-safe reference to the source catalog entry.
    public let ref: MaterialRef

    /// Quantity of this material (stackable)
    public let quantity: Int

    /// Create from InventoryMaterial
    public init(from material: InventoryMaterial) {
        self.ref = material.ref
        self.quantity = material.quantity
    }
}
