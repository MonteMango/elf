//
//  InventoryMaterial.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// Represents a stackable material in the inventory.
/// Materials are identified by their UUID and source repository.
public struct InventoryMaterial: Sendable, Equatable, Codable, Identifiable, Hashable {
    /// Material ID (UUID from the corresponding source repository)
    public let id: UUID

    /// Which repository this material comes from
    public let source: MaterialSource

    /// Quantity of this material (stackable)
    public var quantity: Int

    public init(id: UUID, source: MaterialSource, quantity: Int = 1) {
        self.id = id
        self.source = source
        self.quantity = quantity
    }
}
