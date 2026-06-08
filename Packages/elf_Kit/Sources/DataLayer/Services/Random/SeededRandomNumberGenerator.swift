//
//  SeededRandomNumberGenerator.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

/// Deterministic RNG (SplitMix64). Same seed → same sequence, every run.
///
/// Inject via the standard dependency to make a whole combat / sweep
/// reproducible:
/// ```swift
/// withDependencies {
///     $0.withRandomNumberGenerator = WithRandomNumberGenerator(
///         SeededRandomNumberGenerator(seed: 42)
///     )
/// } operation: { ... }
/// ```
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {

    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
