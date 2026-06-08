//
//  EnduranceService+TestConvenience.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

@testable import elf_Kit

/// Test-only convenience: `calculateBlockCost` defaulting `attackerStrength`
/// to 0, for endurance-focused tests that don't care about attacker pressure.
///
/// Deliberately lives in the **test target**, not on the production protocol:
/// a defaulted overload in production would let real combat code silently
/// disable the strength-burn mechanic by omitting the argument (a balance bug
/// with no symptoms). Tests that DO exercise attacker strength call the full
/// 3-arg method explicitly.
extension EnduranceService {
    func calculateBlockCost(baseCost: Int, defenderEndurance: Int) -> Int {
        calculateBlockCost(baseCost: baseCost, defenderEndurance: defenderEndurance, attackerStrength: 0)
    }
}
