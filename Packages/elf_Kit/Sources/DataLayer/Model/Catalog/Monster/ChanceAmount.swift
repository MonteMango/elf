//
//  ChanceAmount.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public struct ChanceAmount: Codable, Sendable, Hashable {
    public let amount: Int
    public let chance: Double

    public init(amount: Int, chance: Double) {
        self.amount = amount
        self.chance = chance
    }
}
