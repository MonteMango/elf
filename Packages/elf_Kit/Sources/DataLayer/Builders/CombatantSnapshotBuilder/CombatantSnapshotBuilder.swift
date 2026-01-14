//
//  CombatantSnapshotBuilder.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.12.25.
//

import Foundation

/// Builder protocol for creating CombatantSnapshot instances from various sources.
/// Unified builder for both elves and monsters.
public protocol CombatantSnapshotBuilder: Sendable {

    /// Build a CombatantSnapshot from elf configuration data
    /// - Parameters:
    ///   - name: Display name for the combatant
    ///   - imageName: Image asset name for UI display
    ///   - level: Hero level (1-12)
    ///   - fightStyleAttributes: Attributes from selected fight style
    ///   - randomLevelAttributes: Random attributes gained from levels
    ///   - selectedItems: Dictionary of selected item UUIDs by type
    /// - Returns: Constructed CombatantSnapshot or nil if conversion failed
    func buildSnapshot(
        name: String,
        imageName: String,
        level: Int,
        fightStyleAttributes: HeroAttributes,
        randomLevelAttributes: HeroAttributes,
        selectedItems: [HeroItemType: UUID?]
    ) async -> CombatantSnapshot?

    /// Build a CombatantSnapshot from a Monster
    /// - Parameter monster: The Monster to create a snapshot from
    /// - Returns: A CombatantSnapshot representing the monster's combat state
    func buildSnapshot(from monster: Monster) -> CombatantSnapshot
}
