//
//  HerbData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct HerbData: Codable, Sendable {
    public let version: String
    public let effects: [EffectDefinition]
    public let areas: [String: HerbArea]
    public let herbs: [Herb]

    public init(
        version: String,
        effects: [EffectDefinition],
        areas: [String: HerbArea],
        herbs: [Herb]
    ) {
        self.version = version
        self.effects = effects
        self.areas = areas
        self.herbs = herbs
    }
}

// MARK: - GatherableData

extension HerbData: GatherableData {
    public var items: [Herb] { herbs }

    public static var empty: HerbData {
        HerbData(version: "1.0-empty", effects: [], areas: [:], herbs: [])
    }
}
