//
//  DuelPairsColumnView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Displays two vertical columns of combatants representing duel pairs.
/// Active pair is shown at the bottom with larger images.
/// Waiting combatants (without pair) are shown at the top with empty slot on opposite side.
struct DuelPairsColumnView: View {
    let battleRound: BattleRound
    let leftTeam: [CombatantSnapshot]
    let rightTeam: [CombatantSnapshot]

    /// Returns combatant snapshot by ID
    private func snapshot(for id: UUID) -> CombatantSnapshot? {
        leftTeam.first { $0.id == id } ?? rightTeam.first { $0.id == id }
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(alignment: .bottom, spacing: 4) {
            // Left column
            VStack(alignment: .trailing, spacing: 8) {
                // Waiting left combatants (top, no pair)
                ForEach(battleRound.waitingLeftIds, id: \.self) { id in
                    if let combatant = snapshot(for: id) {
                        CombatantImageView(snapshot: combatant, isActive: false)
                    }
                }

                // Other pairs (non-active, from last to first)
                ForEach(battleRound.otherPairs.reversed()) { pair in
                    if let combatant = snapshot(for: pair.leftCombatantId) {
                        CombatantImageView(snapshot: combatant, isActive: false)
                    }
                }

                // Active pair (bottom, larger)
                if let activePair = battleRound.activePair,
                   let combatant = snapshot(for: activePair.leftCombatantId) {
                    CombatantImageView(snapshot: combatant, isActive: true)
                }
            }

            // Separator
            Rectangle()
                .fill(ElfColors.Background.overlayLight)
                .frame(width: 2)

            // Right column
            VStack(alignment: .leading, spacing: 8) {
                // Waiting right combatants (top, no pair)
                ForEach(battleRound.waitingRightIds, id: \.self) { id in
                    if let combatant = snapshot(for: id) {
                        CombatantImageView(snapshot: combatant, isActive: false)
                    }
                }

                // Empty slots for waiting left (to align with left column)
                ForEach(battleRound.waitingLeftIds, id: \.self) { _ in
                    Color.clear
                        .frame(
                            width: ElfSizing.BattleFight.teamImageSize,
                            height: ElfSizing.BattleFight.teamImageSize
                        )
                }

                // Other pairs (non-active, from last to first)
                ForEach(battleRound.otherPairs.reversed()) { pair in
                    if let combatant = snapshot(for: pair.rightCombatantId) {
                        CombatantImageView(snapshot: combatant, isActive: false)
                    }
                }

                // Active pair (bottom, larger)
                if let activePair = battleRound.activePair,
                   let combatant = snapshot(for: activePair.rightCombatantId) {
                    CombatantImageView(snapshot: combatant, isActive: true)
                }
            }
        }
    }
}

#Preview {
    let leftTeam = [
        CombatantSnapshot(
            id: UUID(),
            sourceId: UUID(),
            name: "Elf A",
            imageName: "elf_player",
            combatantType: .elf,
            currentHP: 100,
            maxHP: 100,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 5,
            maximumAttack: 10,
            armorValues: [:]
        ),
        CombatantSnapshot(
            id: UUID(),
            sourceId: UUID(),
            name: "Elf B",
            imageName: "elf_player",
            combatantType: .elf,
            currentHP: 100,
            maxHP: 100,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 5,
            maximumAttack: 10,
            armorValues: [:]
        ),
        CombatantSnapshot(
            id: UUID(),
            sourceId: UUID(),
            name: "Elf C",
            imageName: "elf_player",
            combatantType: .elf,
            currentHP: 100,
            maxHP: 100,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 5,
            maximumAttack: 10,
            armorValues: [:]
        )
    ]

    let rightTeam = [
        CombatantSnapshot(
            id: UUID(),
            sourceId: UUID(),
            name: "Goblin D",
            imageName: "monster_goblin",
            combatantType: .monster,
            currentHP: 80,
            maxHP: 80,
            strength: 8,
            agility: 12,
            power: 8,
            intuition: 8,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 3,
            maximumAttack: 8,
            armorValues: [:]
        ),
        CombatantSnapshot(
            id: UUID(),
            sourceId: UUID(),
            name: "Goblin E",
            imageName: "monster_goblin",
            combatantType: .monster,
            currentHP: 80,
            maxHP: 80,
            strength: 8,
            agility: 12,
            power: 8,
            intuition: 8,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 3,
            maximumAttack: 8,
            armorValues: [:]
        )
    ]

    let battleRound = BattleRound(
        roundNumber: 1,
        duelPairs: [
            DuelPair(leftCombatantId: leftTeam[0].id, rightCombatantId: rightTeam[0].id),
            DuelPair(leftCombatantId: leftTeam[1].id, rightCombatantId: rightTeam[1].id)
        ],
        waitingLeftIds: [leftTeam[2].id],
        waitingRightIds: []
    )

    return DuelPairsColumnView(
        battleRound: battleRound,
        leftTeam: leftTeam,
        rightTeam: rightTeam
    )
    .padding()
    .background(Color.yellow)
}
