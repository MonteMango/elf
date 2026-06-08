//
//  PassthroughBuffEffectsCalculator.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

@testable import elf_Kit

/// Passthrough `BuffEffectsCalculator` — buffs do not alter base attributes.
/// Shared default for tests whose subject pulls `\.buffEffectsCalculator`
/// via `@Dependency` but whose assertions don't involve buff math
/// (combat calculator, snapshot builder, …).
final class PassthroughBuffEffectsCalculator: BuffEffectsCalculator, @unchecked Sendable {
    func apply(buffs: [AppliedBuff], to base: HeroAttributes) -> HeroAttributes {
        base
    }
}
