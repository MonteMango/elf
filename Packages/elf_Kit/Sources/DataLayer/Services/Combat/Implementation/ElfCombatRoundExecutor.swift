//
//  ElfCombatRoundExecutor.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

public final class ElfCombatRoundExecutor: CombatRoundExecutor {

    // MARK: - Dependencies

    private let snapshotCombatCalculator: SnapshotCombatCalculator
    private let damageService: DamageService

    // MARK: - Initialization

    public init(
        snapshotCombatCalculator: SnapshotCombatCalculator,
        damageService: DamageService
    ) {
        self.snapshotCombatCalculator = snapshotCombatCalculator
        self.damageService = damageService
    }

    // MARK: - CombatRoundExecutor

    public func executeRound(
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerAttackPoints: Set<BodyPart>,
        playerDefensePoints: Set<BodyPart>,
        botAttackPoints: Set<BodyPart>,
        botDefensePoints: Set<BodyPart>
    ) async -> CombatRoundResult {
        // Calculate combat results in parallel
        async let playerResultsTask = snapshotCombatCalculator.calculatePointStatus(
            attackingPoints: botAttackPoints,
            defendingPoints: playerDefensePoints,
            attacker: botSnapshot,
            defender: playerSnapshot
        )

        async let botResultsTask = snapshotCombatCalculator.calculatePointStatus(
            attackingPoints: playerAttackPoints,
            defendingPoints: botDefensePoints,
            attacker: playerSnapshot,
            defender: botSnapshot
        )

        // Await both results
        let (playerResults, botResults) = await (playerResultsTask, botResultsTask)

        // Calculate total damage
        let playerDamageTaken = await damageService.calculateTotalDamage(from: playerResults)
        let botDamageTaken = await damageService.calculateTotalDamage(from: botResults)

        return CombatRoundResult(
            playerResults: playerResults,
            botResults: botResults,
            playerDamageTaken: playerDamageTaken,
            botDamageTaken: botDamageTaken
        )
    }
}