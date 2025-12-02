//
//  ManualBattleRoundLog.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public struct ManualBattleRoundLog: Sendable {
    public let roundNumber: Int // current round number

    public var action: [ElfHero: BattleRoundAction] // which actions were made (what attacked, what defended) For each elfHero
    public var duels: [(ElfHero, ElfHero)] // the opponents for current round (could be different in next round)
    public var calculatedPreResults: [ElfHero: BattleRoundCalculatedPreResult] // pre calculation for calculation results
    public var results: [ElfHero: BattleRoundResult] // the result of the round
}
