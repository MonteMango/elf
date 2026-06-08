//
//  BotAIService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Dependencies

public protocol BotAIService: Sendable {
    /// Select attack points based on count.
    /// - Parameters:
    ///   - count: Number of attack points to select
    ///   - generator: Per-battle random source, threaded from the battle boundary.
    /// - Returns: Set of body parts to attack
    func selectAttackPoints(count: Int, using generator: WithRandomNumberGenerator) -> Set<BodyPart>

    /// Select defense points based on count.
    /// - Parameters:
    ///   - count: Number of defense points to select
    ///   - generator: Per-battle random source, threaded from the battle boundary.
    /// - Returns: Set of body parts to defend
    func selectDefensePoints(count: Int, using generator: WithRandomNumberGenerator) -> Set<BodyPart>
}

public extension BotAIService {
    /// Convenience: resolves `\.withRandomNumberGenerator` once and delegates.
    func selectAttackPoints(count: Int) -> Set<BodyPart> {
        @Dependency(\.withRandomNumberGenerator) var generator
        return selectAttackPoints(count: count, using: generator)
    }

    /// Convenience: resolves `\.withRandomNumberGenerator` once and delegates.
    func selectDefensePoints(count: Int) -> Set<BodyPart> {
        @Dependency(\.withRandomNumberGenerator) var generator
        return selectDefensePoints(count: count, using: generator)
    }
}
