//
//  DefaultWorldTurnMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Default `WorldTurnMutator`. Delegates the per-slot experience/drops
/// computation to the injected `RosterProgressionMutator`, mirroring the
/// rules formerly inlined on `GameSession`.
public final class DefaultWorldTurnMutator: WorldTurnMutator {

    private let rosterProgressionMutator: any RosterProgressionMutator

    public init() {
        @Dependency(\.rosterProgressionMutator) var rosterProgressionMutator
        self.rosterProgressionMutator = rosterProgressionMutator
    }

    // MARK: - WorldTurnMutator

    public func applyWorldTurn(_ outcome: WorldTurnOutcome, to houses: [House]) -> [House] {
        var houses = houses
        for result in outcome.results {
            let houseIndex = result.slot.houseIndex
            let memberIndex = result.slot.memberIndex
            guard isValidSlot(houseIndex: houseIndex, memberIndex: memberIndex, in: houses),
                  houses[houseIndex].members[memberIndex].id == result.slot.id else {
                continue
            }

            houses[houseIndex].members[memberIndex].currentExp = rosterProgressionMutator.addExperience(
                result.experienceGained, to: houses[houseIndex].members[memberIndex].currentExp
            )
            houses[houseIndex].members[memberIndex].inventory = rosterProgressionMutator.addDrops(
                materials: result.materials,
                weapons: result.weapons,
                armor: result.armor,
                to: houses[houseIndex].members[memberIndex].inventory
            )
            let currentAP = houses[houseIndex].members[memberIndex].actionPoints
            if case .success(let newPoints) = currentAP.spend(result.actionPointsSpent) {
                houses[houseIndex].members[memberIndex].actionPoints = newPoints
            }
        }
        return houses
    }

    /// Whether `(houseIndex, memberIndex)` addresses a real slot in `houses`.
    private func isValidSlot(houseIndex: Int, memberIndex: Int, in houses: [House]) -> Bool {
        houseIndex >= 0 && houseIndex < houses.count
            && memberIndex >= 0 && memberIndex < houses[houseIndex].members.count
    }
}
