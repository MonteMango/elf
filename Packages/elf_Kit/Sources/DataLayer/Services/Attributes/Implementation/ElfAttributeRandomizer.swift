//
//  ElfAttributeRandomizer.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.07.25.
//

import Dependencies

/// Uniform random pick across the five `RandomAttributeKind` cases.
/// Used by `ElfAttributeService` to roll the +4 random points granted per
/// level. Randomness flows through `\.withRandomNumberGenerator` so the
/// roll is seedable in tests / deterministic sweeps.
public struct ElfAttributeRandomizer: AttributeRandomizer {

    private let withRandomNumberGenerator: WithRandomNumberGenerator

    public init() {
        @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator
        self.withRandomNumberGenerator = withRandomNumberGenerator
    }

    public func nextAttribute() -> RandomAttributeKind {
        withRandomNumberGenerator { generator in
            RandomAttributeKind.allCases.randomElement(using: &generator) ?? .strength
        }
    }
}
