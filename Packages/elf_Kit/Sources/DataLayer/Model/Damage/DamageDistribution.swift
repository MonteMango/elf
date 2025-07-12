//
//  DamageDistribution.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.07.25.
//

public struct DamageDistribution: Equatable {
    public let values: [Int16]
    public let weights: [Int]

    public init(values: [Int16], weights: [Int]) {
        self.values = values
        self.weights = weights
    }
}
