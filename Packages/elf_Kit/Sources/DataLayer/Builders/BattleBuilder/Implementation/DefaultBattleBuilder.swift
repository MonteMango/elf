//
//  DefaultBattleBuilder.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultBattleBuilder: BattleBuilder {

    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let progressionService: any ProgressionService

    public init() {
        @Dependency(\.snapshotBuilder) var snapshotBuilder
        @Dependency(\.progressionService) var progressionService
        self.snapshotBuilder = snapshotBuilder
        self.progressionService = progressionService
    }

    // MARK: - BattleBuilder

    public func buildBattle(party: [BattlePartyMember], monsters: [Monster]) -> Battle? {
        var leftTeam: [CombatantSnapshot] = []
        var equipped: [CombatantID: EquippedItems] = [:]
        for member in party {
            let elf = member.elf
            var snapshot = snapshotBuilder.buildSnapshot(
                elf: elf,
                level: progressionService.calculateLevel(currentExp: elf.currentExp),
                globalBuffs: elf.globalBuffs
            )
            // The builder seeds full reserves; carry over the run's current HP/MP
            // when supplied (dungeon runs), clamped to the snapshot's effective cap.
            if let hp = member.currentHP { snapshot.currentHP = min(hp, snapshot.maxHP) }
            if let mp = member.currentMP { snapshot.currentMP = min(mp, snapshot.maxMP) }
            leftTeam.append(snapshot)
            equipped[snapshot.id] = elf.equipped
        }
        guard !leftTeam.isEmpty else { return nil }

        let rightTeam = monsters.map { snapshotBuilder.buildSnapshot(from: $0, globalBuffs: []) }
        guard !rightTeam.isEmpty else { return nil }

        return Battle(
            leftTeam: leftTeam,
            rightTeam: rightTeam,
            equippedByCombatantId: equipped
        )
    }
}
