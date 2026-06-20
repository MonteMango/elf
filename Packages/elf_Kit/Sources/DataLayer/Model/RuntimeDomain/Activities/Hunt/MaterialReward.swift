//
//  MaterialReward.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import Foundation

/// A material drop with its quantity
public struct MaterialReward: Sendable, Equatable, Hashable, Codable {
    public let id: MaterialID
    public let amount: Int

    public init(id: MaterialID, amount: Int) {
        self.id = id
        self.amount = amount
    }
}
