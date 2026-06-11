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
    public let ref: MaterialRef
    public let quantity: Int

    public init(ref: MaterialRef, quantity: Int) {
        self.ref = ref
        self.quantity = quantity
    }
}
