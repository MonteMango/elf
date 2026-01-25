//
//  FishData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import Foundation

public struct FishData: Codable, Sendable {
    public let version: String
    public let effects: [EffectDefinition]
    public let areas: [String: FishArea]
    public let fish: [Fish]

    public init(
        version: String,
        effects: [EffectDefinition],
        areas: [String: FishArea],
        fish: [Fish]
    ) {
        self.version = version
        self.effects = effects
        self.areas = areas
        self.fish = fish
    }
}
