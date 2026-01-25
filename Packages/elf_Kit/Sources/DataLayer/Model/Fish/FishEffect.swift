//
//  FishEffect.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import Foundation

public struct FishEffect: Codable, Sendable, Hashable {
    public let type: FishEffectType
    public let amount: Int

    public init(type: FishEffectType, amount: Int) {
        self.type = type
        self.amount = amount
    }
}
