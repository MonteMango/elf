//
//  BotTurnPlan.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// What a single AI elf intends to do this day: the elf's roster slot plus the
/// ordered list of actions to execute. Produced by `BotDecisionMaker` (hard
/// coded today, AI-driven later) and consumed by `BotTurnSimulator`.
///
/// The plan is a pure value type with no reference to game state, so it can
/// cross actor boundaries into the off-main simulation freely.
public struct BotTurnPlan: Sendable, Equatable {
    public let slot: RosterSlot
    public let actions: [BotAction]

    public init(slot: RosterSlot, actions: [BotAction]) {
        self.slot = slot
        self.actions = actions
    }

    /// Total action points the plan will consume if every action runs.
    public var totalCost: Int {
        actions.reduce(0) { $0 + $1.cost }
    }
}
