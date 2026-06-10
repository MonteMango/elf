//
//  Herb.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct Herb: Codable, Sendable, Identifiable, Hashable {
    public let id: HerbID
    public let title: String
    public let imageName: String
    public let description: String
    public let tier: ItemTier
    public let baseGatherChance: Double
    public let effects: [HerbEffect]

    public init(
        id: HerbID,
        title: String,
        imageName: String,
        description: String,
        tier: ItemTier,
        baseGatherChance: Double,
        effects: [HerbEffect]
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.description = description
        self.tier = tier
        self.baseGatherChance = baseGatherChance
        self.effects = effects
    }
}

// MARK: - GatherableItem

extension Herb: GatherableItem {
    public var baseSuccessChance: Double { baseGatherChance }
}
