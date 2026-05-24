//
//  ElfEnduranceService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public final class ElfEnduranceService: EnduranceService {

    public init() {}

    public func calculateBlockCost(baseCost: Int, defenderEndurance: Int) -> Int {
        guard baseCost > 0 else { return 0 }

        let pool = GameMechanicsConstants.startingEP
        let endurance = max(0, defenderEndurance)
        let blocksPerPoint = GameMechanicsConstants.blocksPerEndurancePoint
        // Canonical formula:
        //     cost = pool / (pool/baseCost + endurance * blocksPerPoint)
        // With the default `blocksPerPoint = 0.5`, every +2 Endurance grants
        // exactly +1 effective block regardless of weapon.
        let denom = Double(pool) / Double(baseCost) + Double(endurance) * blocksPerPoint
        let raw = Int((Double(pool) / denom).rounded())
        // Clamp to ≥1: extreme endurance values would otherwise round the cost
        // to 0, which the calculator's `blockCost > 0` guard treats as "no
        // cost ⇒ no protection". We prefer "blocks always cost at least 1".
        return max(1, raw)
    }
}
