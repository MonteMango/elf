//
//  GatherableData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Protocol for data collections loaded from JSON (FishData, HerbData, etc.)
public protocol GatherableData: Codable, Sendable {
    associatedtype Item: GatherableItem

    var version: String { get }
    var effects: [EffectDefinition] { get }
    var items: [Item] { get }

    /// Returns an empty instance used as fallback when loading fails.
    static var empty: Self { get }
}
