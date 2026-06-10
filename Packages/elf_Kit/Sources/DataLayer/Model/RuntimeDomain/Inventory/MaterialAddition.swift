//
//  MaterialAddition.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Describes a single material to add to inventory in a batch operation.
/// Used by `InventoryService.addMaterials(_:to:)` to avoid per-item
/// allocations when adding many materials at once.
public struct MaterialAddition: Sendable, Equatable, Hashable {
    public let id: UUID
    public let source: MaterialSource
    public let quantity: Int

    public init(id: UUID, source: MaterialSource, quantity: Int) {
        self.id = id
        self.source = source
        self.quantity = quantity
    }
}
