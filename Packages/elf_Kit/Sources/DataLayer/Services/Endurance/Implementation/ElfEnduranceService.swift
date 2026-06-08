//
//  ElfEnduranceService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfEnduranceService: EnduranceService {

    public init() {}

    public func calculateBlockCost(baseCost: Int, defenderEndurance: Int, attackerStrength: Int) -> Int {
        guard baseCost > 0 else { return 0 }

        let pool = GameMechanicsConstants.startingEP
        let endurance = max(0, defenderEndurance)
        let strength = max(0, attackerStrength)
        let blocksPerEndPoint = GameMechanicsConstants.blocksPerEndurancePoint
        let blocksLostPerStrPoint = GameMechanicsConstants.blocksLostPerAttackerStrength

        // Canonical formula, both modifiers in the same "blocks" abstraction:
        //   cost = pool / (pool/baseCost
        //                  + endurance × blocksPerEndurancePoint        // adds blocks
        //                  − attackerStrength × blocksLostPerAttackerStrength) // burns blocks
        //
        // With defaults (blocksPerEnd = 0.3, blocksLostPerStr = 0.1):
        // - +2 Endurance grants ~+0.6 effective block.
        // - +10 attacker Strength burns ~1 effective block from the defender.
        let denom = Double(pool) / Double(baseCost)
                  + Double(endurance) * blocksPerEndPoint
                  - Double(strength) * blocksLostPerStrPoint

        // Floor the denominator at 1.0 so block cost can't go infinite or
        // negative when an attacker out-strengths the defender's Endurance
        // budget completely. Mirrors the "blocks always cost at least 1"
        // floor we keep on the final cost.
        let safeDenom = max(1.0, denom)
        let raw = Int((Double(pool) / safeDenom).rounded())
        return max(1, raw)
    }
}
