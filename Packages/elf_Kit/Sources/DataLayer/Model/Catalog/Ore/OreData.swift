//
//  OreData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct OreData: Codable, Sendable {
    public let version: String
    public let effects: [EffectDefinition]
    public let areas: [String: OreArea]
    public let ores: [Ore]

    public init(
        version: String,
        effects: [EffectDefinition],
        areas: [String: OreArea],
        ores: [Ore]
    ) {
        self.version = version
        self.effects = effects
        self.areas = areas
        self.ores = ores
    }
}

// MARK: - GatherableData

extension OreData: GatherableData {
    public var items: [Ore] { ores }

    public static var empty: OreData {
        OreData(version: "1.0-empty", effects: [], areas: [:], ores: [])
    }
}
