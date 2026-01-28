//
//  Fish.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import Foundation

public struct Fish: Codable, Sendable, Identifiable, Hashable {
    public let id: FishID
    public let title: String
    public let imageName: String
    public let description: String
    public let tier: GatherableTier
    public let baseCatchChance: Double
    public let effects: [FishEffect]

    public init(
        id: FishID,
        title: String,
        imageName: String,
        description: String,
        tier: GatherableTier,
        baseCatchChance: Double,
        effects: [FishEffect]
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.description = description
        self.tier = tier
        self.baseCatchChance = baseCatchChance
        self.effects = effects
    }
}

// MARK: - GatherableItem

extension Fish: GatherableItem {
    public var baseSuccessChance: Double { baseCatchChance }
}
