//
//  FarmActivityItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Unified item representation for farm activity grids (fish, herbs, minerals)
public struct FarmActivityItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let imageName: String
    public let tier: GatherableTier

    public init(id: UUID, imageName: String, tier: GatherableTier) {
        self.id = id
        self.imageName = imageName
        self.tier = tier
    }
}

// MARK: - Conversions

extension FarmActivityItem {

    /// Create from Fish
    public init(fish: Fish) {
        self.id = fish.id.rawValue
        self.imageName = fish.imageName
        self.tier = fish.tier
    }

    /// Create from Herb
    public init(herb: Herb) {
        self.id = herb.id.rawValue
        self.imageName = herb.imageName
        self.tier = herb.tier
    }

    /// Create from Ore
    public init(ore: Ore) {
        self.id = ore.id.rawValue
        self.imageName = ore.imageName
        self.tier = ore.tier
    }
}

// MARK: - Array Extensions

extension Array where Element == Fish {
    public var asFarmActivityItems: [FarmActivityItem] {
        map { FarmActivityItem(fish: $0) }
    }
}

extension Array where Element == Herb {
    public var asFarmActivityItems: [FarmActivityItem] {
        map { FarmActivityItem(herb: $0) }
    }
}

extension Array where Element == Ore {
    public var asFarmActivityItems: [FarmActivityItem] {
        map { FarmActivityItem(ore: $0) }
    }
}
