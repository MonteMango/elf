//
//  SnapshotCombatCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Dependencies

/// Protocol for calculating combat results using CombatantSnapshot.
/// This is the unified combat calculator that works with any combatant type.
public protocol SnapshotCombatCalculator: Sendable {

    /// Calculate combat results for all body parts based on attack and defense selections
    /// - Parameters:
    ///   - attackingPoints: Body parts being attacked
    ///   - defendingPoints: Body parts being defended
    ///   - attacker: Snapshot of the attacking combatant
    ///   - defender: Snapshot of the defending combatant
    ///   - generator: Per-battle random source, threaded from the battle boundary.
    /// - Returns: Dictionary mapping body parts to their combat status
    func calculatePointStatus(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot,
        using generator: WithRandomNumberGenerator
    ) -> [BodyPart: PointStatus]
}

public extension SnapshotCombatCalculator {
    /// Convenience: resolves `\.withRandomNumberGenerator` once and delegates.
    func calculatePointStatus(
        attackingPoints: Set<BodyPart>,
        defendingPoints: Set<BodyPart>,
        attacker: CombatantSnapshot,
        defender: CombatantSnapshot
    ) -> [BodyPart: PointStatus] {
        @Dependency(\.withRandomNumberGenerator) var generator
        return calculatePointStatus(
            attackingPoints: attackingPoints,
            defendingPoints: defendingPoints,
            attacker: attacker,
            defender: defender,
            using: generator
        )
    }
}
