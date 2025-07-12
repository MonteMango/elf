//
//  ElfAttributeRandomizer.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.07.25.
//

import Foundation

public final class ElfAttributeRandomizer: AttributeRandomizer {
    private let weightedAttributes: [(String, Double)]  // имя + вес
    private let totalWeight: Double

    public init() {
        self.weightedAttributes = [
            ("hitPoints", 0.10),
            ("manaPoints", 0.02),
            ("agility", 0.22),
            ("strength", 0.22),
            ("power", 0.22),
            ("instinct", 0.22)
        ]
        self.totalWeight = weightedAttributes.map { $0.1 }.reduce(0, +)
    }

    public func nextAttribute() -> String {
        let r = Double.random(in: 0..<totalWeight)
        var cumulative: Double = 0
        
        for (attribute, weight) in weightedAttributes {
            cumulative += weight
            if r < cumulative {
                return attribute
            }
        }

        // fallback (должно быть невозможно, но для безопасности)
        return weightedAttributes.last!.0
    }
}
