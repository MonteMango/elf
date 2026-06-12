//
//  BotAction.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// A single action an AI elf can take during the world turn, each consuming a
/// fixed amount of action points. The decision layer (`BotDecisionMaker`)
/// produces a list of these; the simulator (`BotTurnSimulator`) executes them.
///
/// Currently the only action is `hunt` (20 AP); future cases (`.farm`,
/// `.craft`, `.rest`, …) slot in here without changing the execution machinery.
public enum BotAction: Sendable, Equatable, Hashable {
    /// Run one hunt: a 1v1 battle against a level-appropriate monster. Costs
    /// `BotAction.huntCost` AP.
    case hunt

    /// Action point cost of a single hunt. Mirrors `HuntViewModel.huntCost`.
    public static let huntCost = 20

    /// Action point cost of performing this action.
    public var cost: Int {
        switch self {
        case .hunt: BotAction.huntCost
        }
    }
}
