//
//  BattleSimulationService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import Foundation

/// Service for simulating battles between bots
///
/// Runs the battle loop, calculates combat results, and collects statistics.
/// Used by AutoBattleViewModel and MultiBattleViewModel.
public protocol BattleSimulationService: Sendable {

    /// Run a single battle simulation and return the result
    ///
    /// - Parameter battle: The battle configuration with both teams
    /// - Returns: Complete battle result including winner, rounds, and statistics
    func runSingleBattle(_ battle: Battle) async -> BattleResult
}
