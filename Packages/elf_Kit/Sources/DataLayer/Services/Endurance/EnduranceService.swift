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
/// Formula:
/// `cost = round( pool / ( pool/baseCost
///                         + endurance × blocksPerEndurancePoint
///                         − attackerStrength × blocksLostPerAttackerStrength ) )`
/// Both modifiers read in the same "blocks" units. See
/// `GameMechanicsConstants.blocksPerEndurancePoint` /
/// `blocksLostPerAttackerStrength`.
public protocol EnduranceService: Sendable {

    /// Calculate the EP cost for one block.
    ///
    /// - Parameters:
    ///   - baseCost: Attacker-side base cost (weapon `epBlockCost` or monster `epBlockCost`).
    ///   - defenderEndurance: Defender's endurance attribute.
    ///   - attackerStrength: Attacker's strength attribute. Stronger attackers
    ///     burn effective blocks from the defender's pool via
    ///     `GameMechanicsConstants.blocksLostPerAttackerStrength`. Symmetric
    ///     counterpart to Endurance's `blocksPerEndurancePoint` — both
    ///     modifiers read in the same "blocks" units. The production combat
    ///     path always supplies the attacker's real strength
    ///     (`ElfSnapshotCombatCalculator`); there is intentionally **no**
    ///     defaulted overload, so no caller can silently disable the
    ///     strength-burn mechanic by omitting it.
    /// - Returns: Final EP cost the defender pays for one successful block.
    func calculateBlockCost(baseCost: Int, defenderEndurance: Int, attackerStrength: Int) -> Int
}
