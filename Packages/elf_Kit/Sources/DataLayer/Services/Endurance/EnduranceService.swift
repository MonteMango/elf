//
//  EnduranceService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Service for computing the EP cost imposed on a defender per blocked attack,
/// after applying defender endurance reduction. Pure function — no randomness.
///
/// Formula: `cost = round( pool / ( pool/baseCost + endurance/2 ) )`
/// Equivalent to the bonus-pool model in `attributes.md`.
public protocol EnduranceService: Sendable {

    /// Calculate the EP cost for one block.
    ///
    /// - Parameters:
    ///   - baseCost: Attacker-side base cost (weapon `epBlockCost` or monster `epBlockCost`).
    ///   - defenderEndurance: Defender's endurance attribute.
    /// - Returns: Final EP cost the defender pays for one successful block.
    func calculateBlockCost(baseCost: Int, defenderEndurance: Int) -> Int
}
