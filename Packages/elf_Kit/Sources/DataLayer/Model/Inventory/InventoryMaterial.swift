//
//  InventoryMaterial.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// Represents a stackable material in the inventory.
/// Materials are identified by their UUID from MaterialsData and have a quantity.
public struct InventoryMaterial: Sendable, Equatable, Codable, Identifiable, Hashable {
    /// Material ID from MaterialsData (monsters_drop)
    public let id: UUID

    /// Quantity of this material (stackable)
    public var quantity: Int

    public init(id: UUID, quantity: Int = 1) {
        self.id = id
        self.quantity = quantity
    }
}
