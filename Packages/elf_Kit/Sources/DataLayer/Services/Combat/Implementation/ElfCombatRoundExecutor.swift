//
//  ElfCombatRoundExecutor.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Dependencies
import Foundation

public final class ElfCombatRoundExecutor: CombatRoundExecutor {

    // MARK: - Dependencies (snapshotted at init)

    private let snapshotCombatCalculator: any SnapshotCombatCalculator
    private let damageService: any DamageService

    // MARK: - Initialization

    public init() {
        @Dependency(\.snapshotCombatCalculator) var snapshotCombatCalculator
        @Dependency(\.damageService) var damageService
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
    ) -> CombatRoundResult {
        let playerResults = snapshotCombatCalculator.calculatePointStatus(
            attackingPoints: botAttackPoints,
            defendingPoints: playerDefensePoints,
            attacker: botSnapshot,
            defender: playerSnapshot
        )

        let botResults = snapshotCombatCalculator.calculatePointStatus(
            attackingPoints: playerAttackPoints,
            defendingPoints: botDefensePoints,
            attacker: playerSnapshot,
            defender: botSnapshot
        )

        let playerDamageTaken = damageService.calculateTotalDamage(from: playerResults)
        let botDamageTaken = damageService.calculateTotalDamage(from: botResults)

        return CombatRoundResult(
            playerResults: playerResults,
            botResults: botResults,
            playerDamageTaken: playerDamageTaken,
            botDamageTaken: botDamageTaken
        )
    }
}
