//
//  DefaultDayCycleMutator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Default `DayCycleMutator`. Reads buff definitions via the injected
/// `BuffsRepository` to resolve expiry, mirroring the rules formerly inlined
/// on `GameSession`.
public final class DefaultDayCycleMutator: DayCycleMutator {

    private let buffsRepository: any BuffsRepository

    public init() {
        @Dependency(\.buffsRepository) var buffsRepository
        self.buffsRepository = buffsRepository
    }

    // MARK: - DayCycleMutator

    public func advanceDay(houses: [House], toDayNumber: Int) -> [House] {
        var houses = houses
        for houseIndex in houses.indices {
            for memberIndex in houses[houseIndex].members.indices {
                let currentAP = houses[houseIndex].members[memberIndex].actionPoints
                houses[houseIndex].members[memberIndex].actionPoints = currentAP.reset()

                let currentBuffs = houses[houseIndex].members[memberIndex].globalBuffs
                let kept = currentBuffs.filter { applied in
                    guard let buff = buffsRepository.getById(id: applied.buffId),
                          let duration = buff.durationDays,
                          let appliedOnDay = applied.appliedOnDay else {
                        return true  // unknown buff, no expiry, or missing day → keep
                    }
                    return toDayNumber - appliedOnDay < duration
                }
                if kept.count != currentBuffs.count {
                    houses[houseIndex].members[memberIndex].globalBuffs = kept
                }
            }
        }
        return houses
    }
}
