//
//  Repository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Base protocol for all data repositories.
/// Repositories are immutable — data is loaded asynchronously at startup
/// (decoding is heavy), then all lookups are synchronous in-memory accesses.
public protocol Repository<ItemType>: Sendable {
    associatedtype ItemType: Identifiable & Sendable where ItemType.ID: Sendable

    /// Get all items.
    func getAll() -> [ItemType]

    /// Get an item by its ID.
    func getById(id: ItemType.ID) -> ItemType?
}
