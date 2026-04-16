//
//  ArrayRepository.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Generic immutable repository for simple collections.
/// Replaces FishRepository, HerbRepository, OreRepository, MaterialRepository.
public final class ArrayRepository<T: Identifiable & Sendable>: Repository
    where T.ID: Hashable & Sendable {

    private let items: [T]
    private let lookup: [T.ID: T]

    public init(items: [T]) {
        self.items = items
        var lookup: [T.ID: T] = [:]
        for item in items {
            lookup[item.id] = item
        }
        self.lookup = lookup
    }

    public func getAll() -> [T] { items }

    public func getById(id: T.ID) -> T? { lookup[id] }
}
