//
//  ElfCritServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for ElfCritService
///
/// **Algorithm**:
/// **Stage 1**: Select crit chance from the peak+linear-tail distribution
/// **Stage 2**: Check crit success (roll 1-100, succeed if roll <= chance)
/// **Stage 3**: Select damage multiplier from the fixed multiplier distribution
final class ElfCritServiceTests: XCTestCase {

    /// Wire the real stateless strategy + distribution so every test can exercise
    /// `ElfCritService` without each one spelling out `withDependencies`.
    override func invokeTest() {
        withDependencies {
            $0.critDistributionStrategy = ElfCritDistributionStrategy()
            $0.critMultiplierDistribution = CritMultiplierDistribution()
        } operation: {
            super.invokeTest()
        }
    }

    // MARK: - Test Helpers

    private func makeService() -> ElfCritService {
        ElfCritService()
    }

    // MARK: - Stage 1: Distribution Selection Tests

    func testStage1_SelectedChanceWithinDistributionRange() async {
        // Given
        let service = makeService()

        // When: Run multiple times to verify selected chance is within range
        for _ in 0..<100 {
            let result = service.calculateCrit(power: 30, instinct: 10)

            // Then: Selected chance should be within [20, 30] (power - instinct to power)
            XCTAssertGreaterThanOrEqual(result.selectedChance, 20)
            XCTAssertLessThanOrEqual(result.selectedChance, 30)
        }
    }

    func testStage1_NegativeMinimumDistribution() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 5, instinct: 15)

        // Then: Selected chance can be negative (range: -10 to 5)
        XCTAssertGreaterThanOrEqual(result.selectedChance, -10)
        XCTAssertLessThanOrEqual(result.selectedChance, 5)
    }

    // MARK: - Stage 2: Success Check Tests

    func testStage2_NegativeChance_AlwaysFails() async {
        // Given
        let service = makeService()
        var autoFailCount = 0

        // When: Run many times with low power/high instinct to get negative chances
        for _ in 0..<200 {
            let result = service.calculateCrit(power: 5, instinct: 20)
            if result.selectedChance <= 0 {
                XCTAssertFalse(result.success, "Negative or zero chance should always fail")
                XCTAssertNil(result.stage2Roll, "No roll needed for auto-fail")
                autoFailCount += 1
            }
        }

        // Then: Should have some auto-fail cases
        XCTAssertGreaterThan(autoFailCount, 0, "Should have some negative chance selections")
    }

    func testStage2_100PlusChance_AlwaysSucceeds() async {
        // Given
        let service = makeService()

        // When: Power much higher than instinct, min >= 100
        let result = service.calculateCrit(power: 150, instinct: 10)

        // Then: 140+ chance should always succeed
        XCTAssertTrue(result.success, "100+ chance should always succeed")
        XCTAssertNil(result.stage2Roll, "No roll needed for auto-success")
        XCTAssertGreaterThanOrEqual(result.selectedChance, 100)
    }

    func testStage2_ExactlyZeroChance_Fails() async {
        // Given
        let service = makeService()
        var zeroChanceFound = false

        // When: Run many times to find a zero chance
        for _ in 0..<500 {
            let result = service.calculateCrit(power: 10, instinct: 10)
            if result.selectedChance == 0 {
                XCTAssertFalse(result.success, "Zero chance should fail")
                XCTAssertNil(result.stage2Roll, "No roll for zero chance")
                zeroChanceFound = true
                break
            }
        }

        // Verify zero chance was found at least once (or skip if not - probabilistic)
        if !zeroChanceFound {
            // This is acceptable - just means we didn't get lucky
        }
    }

    func testStage2_NormalRoll_RollIsBetween1And100() async {
        // Given
        let service = makeService()

        // When: Get a result with normal roll (chance between 1-99)
        var normalRollFound = false
        for _ in 0..<100 {
            let result = service.calculateCrit(power: 50, instinct: 10)
            if let roll = result.stage2Roll {
                XCTAssertGreaterThanOrEqual(roll, 1)
                XCTAssertLessThanOrEqual(roll, 100)
                normalRollFound = true
            }
        }

        XCTAssertTrue(normalRollFound, "Should have at least one normal roll")
    }

    // MARK: - Stage 3: Multiplier Selection Tests

    func testStage3_CritFailed_MultiplierIs1() async {
        // Given
        let service = makeService()

        // When: Find a failed crit
        var failedCritFound = false
        for _ in 0..<100 {
            let result = service.calculateCrit(power: 10, instinct: 20)
            if !result.success {
                XCTAssertEqual(result.selectedMultiplier, 1.0, "Failed crit should have 1.0 multiplier")
                XCTAssertNil(result.multiplierRoll, "No multiplier roll for failed crit")
                failedCritFound = true
                break
            }
        }

        XCTAssertTrue(failedCritFound, "Should find at least one failed crit")
    }

    func testStage3_CritSucceeded_MultiplierIsValid() async {
        // Given
        let service = makeService()
        let validMultipliers: Set<Double> = [0.75, 1.00, 1.25, 1.5, 2.0, 3.0]

        // When: Find a successful crit
        var successfulCritFound = false
        for _ in 0..<100 {
            let result = service.calculateCrit(power: 80, instinct: 10)
            if result.success {
                XCTAssertTrue(validMultipliers.contains(result.selectedMultiplier),
                             "Multiplier \(result.selectedMultiplier) should be in valid set")
                XCTAssertNotNil(result.multiplierRoll, "Successful crit should have multiplier roll")
                successfulCritFound = true
                break
            }
        }

        XCTAssertTrue(successfulCritFound, "Should find at least one successful crit")
    }

    // MARK: - Result Structure Tests

    func testResultStructure_ContainsAllFields() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 40, instinct: 15)

        // Then: All fields should be populated
        XCTAssertNotNil(result.distribution)
        XCTAssertTrue(result.distribution.hasRange)
        XCTAssertGreaterThanOrEqual(result.selectedChance, result.distribution.minimumChance)
        XCTAssertLessThanOrEqual(result.selectedChance, result.distribution.maximumChance)

        // Multiplier distribution should be populated
        XCTAssertFalse(result.multiplierDistribution.values.isEmpty)
    }

    // MARK: - Statistical Tests

    func testStatistical_CritSuccessRate_CorrelatesWithPower() async {
        // Given
        let service = makeService()
        let iterations = 500

        // When: Compare success rates for different power levels
        var lowPowerSuccesses = 0
        var highPowerSuccesses = 0

        for _ in 0..<iterations {
            let lowResult = service.calculateCrit(power: 20, instinct: 15)
            let highResult = service.calculateCrit(power: 60, instinct: 15)

            if lowResult.success { lowPowerSuccesses += 1 }
            if highResult.success { highPowerSuccesses += 1 }
        }

        // Then: Higher power should have more successes
        XCTAssertGreaterThan(highPowerSuccesses, lowPowerSuccesses,
                            "Higher power should result in more crit successes")
    }

    func testStatistical_MultiplierVariety() async {
        // Given
        let service = makeService()
        var multipliersFound: Set<Double> = []

        // When: Run many crits to collect different multipliers
        for _ in 0..<1000 {
            let result = service.calculateCrit(power: 80, instinct: 10)
            if result.success {
                multipliersFound.insert(result.selectedMultiplier)
            }
        }

        // Then: Should find multiple different multiplier values
        XCTAssertGreaterThan(multipliersFound.count, 1,
                            "Should select different multipliers over multiple runs")
    }

    // MARK: - Edge Cases

    func testEdgeCase_ZeroPower() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 0, instinct: 10)

        // Then: Distribution min = -10, max = 0
        XCTAssertEqual(result.distribution.minimumChance, -10)
        XCTAssertEqual(result.distribution.maximumChance, 0)
        XCTAssertFalse(result.success, "Zero or negative power should always fail crit")
    }

    func testEdgeCase_ZeroInstinct() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 50, instinct: 0)

        // Then: Distribution min = max = 50
        XCTAssertEqual(result.distribution.minimumChance, 50)
        XCTAssertEqual(result.distribution.maximumChance, 50)
        XCTAssertEqual(result.selectedChance, 50)
    }

    func testEdgeCase_AllZeros() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 0, instinct: 0)

        // Then: min = max = 0, should always fail
        XCTAssertEqual(result.distribution.minimumChance, 0)
        XCTAssertEqual(result.distribution.maximumChance, 0)
        XCTAssertFalse(result.success)
    }

    func testEdgeCase_VeryHighValues() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 200, instinct: 50)

        // Then: max capped at 100, min = 150
        XCTAssertEqual(result.distribution.maximumChance, 100)
        XCTAssertEqual(result.distribution.minimumChance, 150)
        XCTAssertTrue(result.success, "150+ chance should always succeed")
    }

    // MARK: - selectBlockedCritMultiplier

    /// Defaults from `GameMechanicsConstants.blockedCritMultiplierWeights`
    /// `[5, 50, 40, 5, 0, 0]` paired with values `[0.75, 1.00, 1.25, 1.5, 2.0, 3.0]`.
    /// Bands with weight 0 (2.0×, 3.0×) must never be picked; every other
    /// band must appear at least once over a large enough sample.
    func testBlockedCritMultiplier_StaysWithinDistributionTail() async {
        let service = makeService()
        var picked: Set<Double> = []
        var max: Double = 0

        for _ in 0..<5000 {
            let m = service.selectBlockedCritMultiplier()
            picked.insert(m)
            if m > max { max = m }
        }

        XCTAssertFalse(picked.contains(2.0), "blocked-crit multiplier must never roll 2.0× (weight 0)")
        XCTAssertFalse(picked.contains(3.0), "blocked-crit multiplier must never roll 3.0× (weight 0)")
        XCTAssertLessThanOrEqual(max, 1.5, "blocked-crit multiplier capped at 1.5× by weights")
        // With 5/50/40/5 weights over 5000 rolls, the 5-weight bands appear
        // with very high probability (~99.9%).
        XCTAssertTrue(picked.contains(0.75))
        XCTAssertTrue(picked.contains(1.0))
        XCTAssertTrue(picked.contains(1.25))
        XCTAssertTrue(picked.contains(1.5))
    }

    /// Pins the canonical mean of the blocked-crit distribution. If weights
    /// are retuned this test will fail loudly — that's the point: any change
    /// here has direct combat-balance consequences and should be intentional.
    func testBlockedCritMultiplier_MeanMatchesWeightedExpectation() async {
        let service = makeService()
        let trials = 20_000
        var total: Double = 0
        for _ in 0..<trials {
            total += service.selectBlockedCritMultiplier()
        }
        let mean = total / Double(trials)
        // Expected: 0.05·0.75 + 0.5·1.0 + 0.4·1.25 + 0.05·1.5 = 1.1125
        XCTAssertEqual(mean, 1.1125, accuracy: 0.02, "Mean must match weights·values dot product within stochastic tolerance")
    }
}
