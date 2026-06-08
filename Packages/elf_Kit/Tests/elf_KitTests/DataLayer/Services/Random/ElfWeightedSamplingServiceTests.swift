//
//  ElfWeightedSamplingServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for `ElfWeightedSamplingService.sample(values:weights:)`. Used by
/// `ElfDamageService.weightedRoll`, crit/dodge chance selection, and any
/// consumer that picks one element from a parallel `(values, weights)` pair.
/// Runs on a seeded generator, so the statistical assertions are
/// deterministic.
final class ElfWeightedSamplingServiceTests: XCTestCase {

    override func invokeTest() {
        withDependencies {
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                SeededRandomNumberGenerator(seed: 0xE1F)
            )
        } operation: {
            super.invokeTest()
        }
    }

    private func makeService() -> ElfWeightedSamplingService {
        ElfWeightedSamplingService()
    }

    func testEmptyValues_ReturnsNil() {
        let result: Int? = makeService().sample(values: [], weights: [])
        XCTAssertNil(result)
    }

    func testMismatchedLengths_ReturnsNil() {
        let result = makeService().sample(values: [1, 2, 3], weights: [1, 2])
        XCTAssertNil(result, "Different-length arrays must return nil to surface the caller bug")
    }

    func testAllZeroWeights_ReturnsNil() {
        let result = makeService().sample(values: [1, 2, 3], weights: [0, 0, 0])
        XCTAssertNil(result, "Zero total weight is a degenerate sample — must return nil")
    }

    func testSingleValue_AlwaysReturnsThatValue() {
        let service = makeService()
        for _ in 0..<50 {
            let result = service.sample(values: ["only"], weights: [1])
            XCTAssertEqual(result, "only")
        }
    }

    func testSingleValueLargeWeight_AlwaysReturnsThatValue() {
        let service = makeService()
        for _ in 0..<50 {
            let result = service.sample(values: [42], weights: [1_000_000])
            XCTAssertEqual(result, 42)
        }
    }

    /// Weight=0 buckets must never be picked. Sample many times and assert
    /// only the non-zero-weight buckets show up.
    func testZeroWeightBucket_NeverPicked() {
        let service = makeService()
        var seen: Set<String> = []
        for _ in 0..<2000 {
            if let pick = service.sample(values: ["a", "b", "c"], weights: [10, 0, 5]) {
                seen.insert(pick)
            }
        }
        XCTAssertFalse(seen.contains("b"), "Weight-0 bucket must never be picked")
        XCTAssertTrue(seen.contains("a"))
        XCTAssertTrue(seen.contains("c"))
    }

    /// Monte Carlo: empirical frequencies should track the weight ratio.
    /// `[10, 30, 60]` over 5000 trials → ≈ [10%, 30%, 60%].
    func testEmpiricalDistributionMatchesWeights() {
        let service = makeService()
        let trials = 5000
        let weights = [10, 30, 60]
        let values = [0, 1, 2]
        var counts = [0, 0, 0]
        for _ in 0..<trials {
            if let pick = service.sample(values: values, weights: weights) {
                counts[pick] += 1
            }
        }
        let expected = weights.map { Double($0) / 100.0 }
        for index in 0..<3 {
            let observed = Double(counts[index]) / Double(trials)
            XCTAssertEqual(observed, expected[index], accuracy: 0.04,
                           "index=\(index) expected ≈ \(expected[index]), got \(observed)")
        }
    }

    /// Roll falls into the cumulative range — verify the bucket boundaries
    /// by stressing a two-value [1, 1] split.
    func testEvenSplit_ApproximatelyFiftyFifty() {
        let service = makeService()
        let trials = 5000
        var firstCount = 0
        for _ in 0..<trials {
            if service.sample(values: [true, false], weights: [1, 1]) == true {
                firstCount += 1
            }
        }
        let observed = Double(firstCount) / Double(trials)
        XCTAssertEqual(observed, 0.5, accuracy: 0.04)
    }

    /// Same seed → same sample sequence. The whole point of routing
    /// randomness through `\.withRandomNumberGenerator`.
    func testSeededGenerator_IsReproducible() {
        func sampleSequence() -> [Int?] {
            withDependencies {
                $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                    SeededRandomNumberGenerator(seed: 42)
                )
            } operation: {
                let service = ElfWeightedSamplingService()
                return (0..<20).map { _ in
                    service.sample(values: [1, 2, 3], weights: [1, 2, 3])
                }
            }
        }
        XCTAssertEqual(sampleSequence(), sampleSequence())
    }
}
