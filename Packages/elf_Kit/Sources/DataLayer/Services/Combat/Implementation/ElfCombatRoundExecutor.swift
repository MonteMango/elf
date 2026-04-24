//
//  ElfCombatRoundExecutor.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Dependencies
import Foundation

public final class ElfCombatRoundExecutor: CombatRoundExecutor {

    // MARK: - Dependencies

    private let _snapshotCombatCalculator = Dependency(\.snapshotCombatCalculator)
    private var snapshotCombatCalculator: any SnapshotCombatCalculator { _snapshotCombatCalculator.wrappedValue }

    private let _damageService = Dependency(\.damageService)
    private var damageService: any DamageService { _damageService.wrappedValue }

    // MARK: - Initialization

    public init() {}

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
