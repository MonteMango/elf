//
//  OreEffect.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct OreEffect: Codable, Sendable, Hashable {
    public let type: OreEffectType
    public let amount: Int

    public init(type: OreEffectType, amount: Int) {
        self.type = type
        self.amount = amount
    }
}
