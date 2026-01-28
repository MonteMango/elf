//
//  HerbEffect.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct HerbEffect: Codable, Sendable, Hashable {
    public let type: HerbEffectType
    public let amount: Int

    public init(type: HerbEffectType, amount: Int) {
        self.type = type
        self.amount = amount
    }
}
