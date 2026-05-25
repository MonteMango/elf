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
    let leftCells: [CombatantCellState]
    let rightCells: [CombatantCellState]
    let playerCombatantId: UUID?

    /// Returns the cell descriptor matching the given combatant id, across both teams.
    private func cell(for id: UUID) -> CombatantCellState? {
        leftCells.first { $0.id == id } ?? rightCells.first { $0.id == id }
    }

    /// Pair containing the player on the left side, if present in this round.
    private var heroPair: DuelPair? {
        guard let playerId = playerCombatantId else { return nil }
        return battleRound.duelPairs.first { $0.leftCombatantId == playerId }
    }

    /// All non-hero pairs, in the order produced by the pairing service.
    private var otherPairs: [DuelPair] {
        if let heroPair {
            return battleRound.duelPairs.filter { $0.id != heroPair.id }
        }
        // Hero is alive but not paired (waiting): show every pair above the "hero alone" row.
        // Dropping the first pair would lose a real duel from the UI.
        if isHeroWaiting {
            return battleRound.duelPairs
        }
        // Legacy fallback (no playerId, e.g. dev/auto): first pair is "active".
        return Array(battleRound.duelPairs.dropFirst())
    }

    /// Bottom-row "active" pair: hero's pair when present, otherwise the first random pair
    /// (back-compat for dev/auto flows without a player).
    private var activeBottomPair: DuelPair? {
        heroPair ?? battleRound.duelPairs.first
    }

    /// Hero is alive somewhere in the left team but has no pair this round → render alone.
    private var isHeroWaiting: Bool {
        guard let playerId = playerCombatantId,
              let player = leftCells.first(where: { $0.id == playerId }),
              player.isAlive
        else { return false }
        return heroPair == nil
    }

    private var waitingLeftIdsForDisplay: [UUID] {
        guard isHeroWaiting, let playerId = playerCombatantId else {
            return battleRound.waitingLeftIds
        }
        return battleRound.waitingLeftIds.filter { $0 != playerId }
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(alignment: .bottom, spacing: 4) {
            // Left column
            VStack(alignment: .trailing, spacing: 8) {
                // Waiting left combatants (top, no pair) — hero excluded; he sits at the bottom alone.
                ForEach(waitingLeftIdsForDisplay, id: \.self) { id in
                    if let combatant = cell(for: id) {
                        CombatantImageView(cell: combatant, isActive: false)
                    }
                }

                // Other pairs (non-hero), from last to first
                ForEach(otherPairs.reversed()) { pair in
                    if let combatant = cell(for: pair.leftCombatantId) {
                        CombatantImageView(cell: combatant, isActive: false)
                    }
                }

                // Bottom-active row: hero's pair (or fallback first pair) — large icon.
                if isHeroWaiting,
                   let playerId = playerCombatantId,
                   let player = cell(for: playerId) {
                    CombatantImageView(cell: player, isActive: true)
                } else if let activePair = activeBottomPair,
                          let combatant = cell(for: activePair.leftCombatantId) {
                    CombatantImageView(cell: combatant, isActive: true)
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
                    if let combatant = cell(for: id) {
                        CombatantImageView(cell: combatant, isActive: false)
                    }
                }

                // Empty slots opposite waiting-left rows (to keep both columns aligned)
                ForEach(waitingLeftIdsForDisplay, id: \.self) { _ in
                    Color.clear
                        .frame(
                            width: ElfSizing.BattleFight.teamImageSize,
                            height: ElfSizing.BattleFight.teamImageSize
                        )
                }

                // Other pairs, from last to first
                ForEach(otherPairs.reversed()) { pair in
                    if let combatant = cell(for: pair.rightCombatantId) {
                        CombatantImageView(cell: combatant, isActive: false)
                    }
                }

                // Bottom-active row: opponent of hero's pair, OR an empty large slot when hero waits.
                if isHeroWaiting {
                    Color.clear
                        .frame(
                            width: ElfSizing.BattleFight.teamImageActiveSize,
                            height: ElfSizing.BattleFight.teamImageActiveSize
                        )
                } else if let activePair = activeBottomPair,
                          let combatant = cell(for: activePair.rightCombatantId) {
                    CombatantImageView(cell: combatant, isActive: true)
                }
            }
        }
    }
}

#Preview {
    let leftCells = [
        CombatantCellState(id: UUID(), imageName: "elf_player", isAlive: true),
        CombatantCellState(id: UUID(), imageName: "elf_player", isAlive: true),
        CombatantCellState(id: UUID(), imageName: "elf_player", isAlive: true)
    ]

    let rightCells = [
        CombatantCellState(id: UUID(), imageName: "monster_goblin", isAlive: true),
        CombatantCellState(id: UUID(), imageName: "monster_goblin", isAlive: true)
    ]

    let battleRound = BattleRound(
        roundNumber: 1,
        duelPairs: [
            DuelPair(leftCombatantId: leftCells[0].id, rightCombatantId: rightCells[0].id),
            DuelPair(leftCombatantId: leftCells[1].id, rightCombatantId: rightCells[1].id)
        ],
        waitingLeftIds: [leftCells[2].id],
        waitingRightIds: []
    )

    return DuelPairsColumnView(
        battleRound: battleRound,
        leftCells: leftCells,
        rightCells: rightCells,
        playerCombatantId: leftCells[0].id
    )
    .padding()
    .background(Color.yellow)
}
