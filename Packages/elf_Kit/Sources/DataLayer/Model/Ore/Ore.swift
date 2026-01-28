//
//  Ore.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct Ore: Codable, Sendable, Identifiable, Hashable {
    public let id: OreID
    public let title: String
    public let imageName: String
    public let description: String
    public let tier: GatherableTier
    public let baseMineChance: Double
    public let effects: [OreEffect]

    public init(
        id: OreID,
        title: String,
        imageName: String,
        description: String,
        tier: GatherableTier,
        baseMineChance: Double,
        effects: [OreEffect]
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.description = description
        self.tier = tier
        self.baseMineChance = baseMineChance
        self.effects = effects
    }
}

// MARK: - GatherableItem

extension Ore: GatherableItem {
    public var baseSuccessChance: Double { baseMineChance }
}
