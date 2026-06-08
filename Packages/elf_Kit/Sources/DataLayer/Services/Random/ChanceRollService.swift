//
//  ChanceRollService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

/// Two-stage chance check shared by Dodge and Crit services.
/// - Chance ≤ 0 → auto-fail (no roll).
/// - Chance ≥ 100 → auto-success (no roll).
/// - Otherwise → roll 1...100, succeed if `roll ≤ chance`.
///
/// The generator is passed in (`using:`) so the whole combat chain shares
/// **one** generator per battle — resolved once at the battle boundary and
/// threaded down, never read from `@Dependency` in the per-roll hot loop.
public protocol ChanceRollService: Sendable {

    /// Resolves a percent-chance check with the supplied generator.
    /// - Returns: the 1...100 roll (`nil` on the auto-fail / auto-success
    ///   edges, where no roll happens) and whether the check succeeded.
    func resolve(chance: Int16, using generator: WithRandomNumberGenerator) -> (roll: Int?, success: Bool)
}

public extension ChanceRollService {
    /// Convenience for call sites that don't thread a per-battle generator
    /// (production single battles, unit tests). Resolves
    /// `\.withRandomNumberGenerator` **once** per call and delegates.
    func resolve(chance: Int16) -> (roll: Int?, success: Bool) {
        @Dependency(\.withRandomNumberGenerator) var generator
        return resolve(chance: chance, using: generator)
    }
}
