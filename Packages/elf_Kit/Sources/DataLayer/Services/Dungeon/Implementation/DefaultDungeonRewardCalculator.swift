//
//  DefaultDungeonRewardCalculator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public struct DefaultDungeonRewardCalculator: DungeonRewardCalculator {

    public init() {}

    public func roomRewards(monsters: [MonsterRef]) -> [HuntRewards] {
        // Resolved lazily (not in init) so constructing the calculator doesn't
        // eagerly pull these live-only deps — keeps non-battle flows / tests free
        // of the hunt/monster dependency chain.
        @Dependency(\.huntService) var huntService
        @Dependency(\.monsterRepository) var monsterRepository

        var rewards: [HuntRewards] = []
        for ref in monsters {
            // A ref whose id no longer resolves (catalog drift / typo in the room
            // definition) is skipped with a log rather than vanishing silently —
            // mirrors `DungeonRunRewardsSaveData.toRewards` on the banked-drop side.
            guard let monster = monsterRepository.getById(id: ref.monsterId) else {
                #if DEBUG
                print("[DungeonRewardCalculator] monster \(ref.monsterId) no longer resolves — skipped")
                #endif
                continue
            }
            for _ in 0..<max(1, ref.count) {
                rewards.append(huntService.calculateRewards(for: monster))
            }
        }
        return rewards
    }
}
