//
//  InventoryMaterial.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// Represents a stackable material in the inventory.
/// Identified by a type-safe `MaterialRef` (fish / herb / ore / monster-drop).
public struct InventoryMaterial: Sendable, Equatable, Codable, Identifiable, Hashable {
    /// Type-safe reference to the source catalog entry.
    public let ref: MaterialRef

    /// Quantity of this material (stackable)
    public var quantity: Int

    /// `Identifiable` by the (unique-per-stack) material reference.
    public var id: MaterialRef { ref }

    public init(ref: MaterialRef, quantity: Int = 1) {
        self.ref = ref
        self.quantity = quantity
    }
}
