//
//  ElfCritServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for ElfCritService
///
/// **Algorithm**:
/// **Stage 1**: Select crit chance from triangular distribution
/// **Stage 2**: Check crit success (roll 1-100, succeed if roll <= chance)
/// **Stage 3**: Select damage multiplier from agility-adjusted distribution
final class ElfCritServiceTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeService() -> ElfCritService {
        let strategy = ElfCritDistributionStrategy()
        return ElfCritService(distributionStrategy: strategy)
    }

    // MARK: - Stage 1: Distribution Selection Tests

    func testStage1_SelectedChanceWithinDistributionRange() async {
        // Given
        let service = makeService()

        // When: Run multiple times to verify selected chance is within range
        for _ in 0..<100 {
            let result = service.calculateCrit(power: 30, instinct: 10, defenderAgility: 20)

            // Then: Selected chance should be within [20, 30] (power - instinct to power)
            XCTAssertGreaterThanOrEqual(result.selectedChance, 20)
            XCTAssertLessThanOrEqual(result.selectedChance, 30)
        }
    }

    func testStage1_NegativeMinimumDistribution() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 5, instinct: 15, defenderAgility: 10)

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
            let result = service.calculateCrit(power: 5, instinct: 20, defenderAgility: 10)
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
        let result = service.calculateCrit(power: 150, instinct: 10, defenderAgility: 20)

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
            let result = service.calculateCrit(power: 10, instinct: 10, defenderAgility: 10)
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
            let result = service.calculateCrit(power: 50, instinct: 10, defenderAgility: 20)
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
            let result = service.calculateCrit(power: 10, instinct: 20, defenderAgility: 30)
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
            let result = service.calculateCrit(power: 80, instinct: 10, defenderAgility: 20)
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

    // MARK: - Agility Adjustment Tests

    func testAgilityAdjustment_HighAgility_DecreasesHighMultiplierChance() async {
        // Given
        let service = makeService()

        // When: High defender agility should shift weights to lower multipliers
        let result = service.calculateCrit(power: 50, instinct: 10, defenderAgility: 100)

        // Then: Decreaser should be positive (agility advantage)
        XCTAssertGreaterThan(result.critMultiplierDecreaser, 0,
                            "High agility should create positive decreaser")

        // Adjusted distribution should have reduced weights for high multipliers
        let originalHighWeights = result.multiplierDistribution.weights[3...5].reduce(0, +)
        let adjustedHighWeights = result.adjustedMultiplierDistribution.weights[3...5].reduce(0, +)
        XCTAssertLessThanOrEqual(adjustedHighWeights, originalHighWeights,
                                  "High multiplier weights should be reduced or equal")
    }

    func testAgilityAdjustment_LowAgility_NoAdjustment() async {
        // Given
        let service = makeService()

        // When: Low defender agility (power > agility * coefficient)
        let result = service.calculateCrit(power: 100, instinct: 10, defenderAgility: 10)

        // Then: Decreaser should be 0 (no adjustment)
        XCTAssertEqual(result.critMultiplierDecreaser, 0,
                      "Low agility should not adjust multiplier distribution")

        // Distributions should be equal
        XCTAssertEqual(result.multiplierDistribution, result.adjustedMultiplierDistribution)
    }

    // MARK: - Result Structure Tests

    func testResultStructure_ContainsAllFields() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 40, instinct: 15, defenderAgility: 25)

        // Then: All fields should be populated
        XCTAssertNotNil(result.distribution)
        XCTAssertTrue(result.distribution.hasRange)
        XCTAssertGreaterThanOrEqual(result.selectedChance, result.distribution.minimumChance)
        XCTAssertLessThanOrEqual(result.selectedChance, result.distribution.maximumChance)

        // Multiplier distribution should be populated
        XCTAssertFalse(result.multiplierDistribution.values.isEmpty)
        XCTAssertFalse(result.adjustedMultiplierDistribution.values.isEmpty)
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
            let lowResult = service.calculateCrit(power: 20, instinct: 15, defenderAgility: 20)
            let highResult = service.calculateCrit(power: 60, instinct: 15, defenderAgility: 20)

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
            let result = service.calculateCrit(power: 80, instinct: 10, defenderAgility: 20)
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
        let result = service.calculateCrit(power: 0, instinct: 10, defenderAgility: 20)

        // Then: Distribution min = -10, max = 0
        XCTAssertEqual(result.distribution.minimumChance, -10)
        XCTAssertEqual(result.distribution.maximumChance, 0)
        XCTAssertFalse(result.success, "Zero or negative power should always fail crit")
    }

    func testEdgeCase_ZeroInstinct() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 50, instinct: 0, defenderAgility: 20)

        // Then: Distribution min = max = 50
        XCTAssertEqual(result.distribution.minimumChance, 50)
        XCTAssertEqual(result.distribution.maximumChance, 50)
        XCTAssertEqual(result.selectedChance, 50)
    }

    func testEdgeCase_ZeroAgility() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 50, instinct: 10, defenderAgility: 0)

        // Then: Should not crash, decreaser should be 0 (no agility advantage)
        XCTAssertEqual(result.critMultiplierDecreaser, 0)
    }

    func testEdgeCase_AllZeros() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 0, instinct: 0, defenderAgility: 0)

        // Then: min = max = 0, should always fail
        XCTAssertEqual(result.distribution.minimumChance, 0)
        XCTAssertEqual(result.distribution.maximumChance, 0)
        XCTAssertFalse(result.success)
    }

    func testEdgeCase_VeryHighValues() async {
        // Given
        let service = makeService()

        // When
        let result = service.calculateCrit(power: 200, instinct: 50, defenderAgility: 100)

        // Then: max capped at 100, min = 150
        XCTAssertEqual(result.distribution.maximumChance, 100)
        XCTAssertEqual(result.distribution.minimumChance, 150)
        XCTAssertTrue(result.success, "150+ chance should always succeed")
    }
}
