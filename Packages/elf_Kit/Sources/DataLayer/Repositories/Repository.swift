//
//  Repository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Base protocol for all data repositories.
/// All methods are async to guarantee execution off the main thread.
/// Repositories are immutable — data is injected through init.
public protocol Repository<ItemType>: Sendable {
    associatedtype ItemType: Identifiable & Sendable where ItemType.ID: Sendable

    /// Get all items.
    func getAll() async -> [ItemType]

    /// Get an item by its ID.
    func getById(id: ItemType.ID) async -> ItemType?
}
