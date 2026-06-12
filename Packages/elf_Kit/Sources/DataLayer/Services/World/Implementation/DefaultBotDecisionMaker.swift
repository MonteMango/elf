//
//  DefaultBotDecisionMaker.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// Hard-coded world-turn brain: spend the elf's entire action-point budget on
/// hunting. With the default 100 AP and a 20 AP hunt cost, that's 5 hunts.
///
/// This is the placeholder the future AI planner replaces. It is pure and
/// stateless — no dependencies, no game-state access.
public final class DefaultBotDecisionMaker: BotDecisionMaker {

    public init() {}

    public func planTurn(for elf: ElfInfo, at slot: RosterSlot) -> BotTurnPlan {
        let huntCount = elf.actionPoints.current / BotAction.huntCost
        let actions = Array(repeating: BotAction.hunt, count: huntCount)
        return BotTurnPlan(slot: slot, actions: actions)
    }
}
