//
//  ElfAttributeRandomizer.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.07.25.
//

import GameplayKit

public final class ElfAttributeRandomizer: AttributeRandomizer {
    private let weightedAttributes: [String]
    private let distribution: GKShuffledDistribution

    public init() {
        self.weightedAttributes = [
            "hitPoints", "hitPoints",               // 10%
            "manaPoints", "manaPoints",             // 10%
            "agility", "agility", "agility", "agility",  // 20%
            "strength", "strength", "strength", "strength", // 20%
            "power", "power", "power", "power",     // 20%
            "instinct", "instinct", "instinct", "instinct" // 20%
        ]
        
        self.distribution = GKShuffledDistribution(lowestValue: 0, highestValue: weightedAttributes.count - 1)
    }

    public func nextAttribute() -> String {
        let index = distribution.nextInt()
        return weightedAttributes[index]
    }
}
