//
//  BotDecisionMaker.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// Decides what an AI elf does during the world turn — i.e. which day-level
/// actions (hunt, and later farm/craft/rest) it spends its action points on.
///
/// This is the seam for the future AI-driven brain: today the default
/// implementation hard-codes "spend everything on hunting", later it can be
/// swapped for a model-backed planner without touching the execution layer
/// (`BotTurnSimulator` / `WorldTurnRunner`).
///
/// Distinct from `BotAI` (combat move selection within a single battle) — this
/// operates one level up, at the granularity of a whole day's activities.
public protocol BotDecisionMaker: Sendable {

    /// Produce the action plan for one elf's day, bounded by its available
    /// action points.
    /// - Parameters:
    ///   - elf: The AI elf's current state (its `actionPoints` budget the plan).
    ///   - slot: Where the elf lives in the roster, carried through to the plan.
    /// - Returns: The ordered list of actions to execute this turn.
    func planTurn(for elf: ElfInfo, at slot: RosterSlot) -> BotTurnPlan
}
