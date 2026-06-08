//
//  ElfChanceRollService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

public struct ElfChanceRollService: ChanceRollService {

    public init() {}

    public func resolve(chance: Int16, using generator: WithRandomNumberGenerator) -> (roll: Int?, success: Bool) {
        let chanceInt = Int(chance)
        if chanceInt <= 0 { return (nil, false) }
        if chanceInt >= 100 { return (nil, true) }
        let roll = generator { Int.random(in: 1...100, using: &$0) }
        return (roll, roll <= chanceInt)
    }
}
