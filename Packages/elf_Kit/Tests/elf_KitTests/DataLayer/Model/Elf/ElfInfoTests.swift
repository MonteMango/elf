//
//  ElfInfoTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.01.26.
//

import XCTest
@testable import elf_Kit

/// Tests for ElfProgressionService following Type-Driven Design
///
/// TDD principle: "Make impossible states unrepresentable"
/// - `currentExp` is the single source of truth
/// - `level` is always computed from `currentExp`
/// - Formula: level = max(1, min(12, currentExp / 100))
final class ElfInfoTests: XCTestCase {

    // MARK: - Test Helpers

    private var progressionService: ProgressionService!

    override func setUp() {
        super.setUp()
        progressionService = ElfProgressionService()
    }

    override func tearDown() {
        progressionService = nil
        super.tearDown()
    }

    // MARK: - Level Calculation Tests

    func testLevel_zeroXP_returnsOne() {
        // Given
        let level = progressionService.calculateLevel(currentExp: 0)

        // Then
        XCTAssertEqual(level, 1)
    }

    func testLevel_99XP_returnsOne() {
        // Given
        let level = progressionService.calculateLevel(currentExp: 99)

        // Then
        XCTAssertEqual(level, 1)
    }

    func testLevel_100XP_returnsOne() {
        // Given: 100 XP is still within level 1 range (0-199)
        let level = progressionService.calculateLevel(currentExp: 100)

        // Then
        XCTAssertEqual(level, 1)
    }

    func testLevel_199XP_returnsOne() {
        // Given: 199 XP is the max for level 1
        let level = progressionService.calculateLevel(currentExp: 199)

        // Then
        XCTAssertEqual(level, 1)
    }

    func testLevel_200XP_returnsTwo() {
        // Given: 200 XP starts level 2
        let level = progressionService.calculateLevel(currentExp: 200)

        // Then
        XCTAssertEqual(level, 2)
    }

    func testLevel_299XP_returnsTwo() {
        // Given
        let level = progressionService.calculateLevel(currentExp: 299)

        // Then
        XCTAssertEqual(level, 2)
    }

    func testLevel_300XP_returnsThree() {
        // Given
        let level = progressionService.calculateLevel(currentExp: 300)

        // Then
        XCTAssertEqual(level, 3)
    }

    func testLevel_445XP_returnsFour() {
        // Given: 445 XP falls within level 4 (400-499)
        let level = progressionService.calculateLevel(currentExp: 445)

        // Then
        XCTAssertEqual(level, 4)
    }

    func testLevel_1100XP_returnsEleven() {
        // Given
        let level = progressionService.calculateLevel(currentExp: 1100)

        // Then
        XCTAssertEqual(level, 11)
    }

    func testLevel_1200XP_returnsTwelve() {
        // Given: 1200 XP is minimum for max level 12
        let level = progressionService.calculateLevel(currentExp: 1200)

        // Then
        XCTAssertEqual(level, 12)
    }

    func testLevel_9999XP_returnsTwelve_maxCap() {
        // Given: Even with massive XP, level is capped at 12
        let level = progressionService.calculateLevel(currentExp: 9999)

        // Then
        XCTAssertEqual(level, 12)
    }

    func testLevel_negativeXP_returnsOne_minCap() {
        // Given: Negative XP should default to level 1
        let level = progressionService.calculateLevel(currentExp: -100)

        // Then
        XCTAssertEqual(level, 1)
    }

    // MARK: - expToNextLevel Tests

    func testExpToNextLevel_level1_returns200() {
        // Given: Level 1 elf needs to reach 200 XP for level 2
        let expToNext = progressionService.expToNextLevel(currentExp: 0)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 0), 1)
        XCTAssertEqual(expToNext, 200)
    }

    func testExpToNextLevel_level2_returns300() {
        // Given
        let expToNext = progressionService.expToNextLevel(currentExp: 200)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 200), 2)
        XCTAssertEqual(expToNext, 300)
    }

    func testExpToNextLevel_level11_returns1200() {
        // Given
        let expToNext = progressionService.expToNextLevel(currentExp: 1100)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 1100), 11)
        XCTAssertEqual(expToNext, 1200)
    }

    func testExpToNextLevel_level12_returnsZero() {
        // Given: Max level has no next level
        let expToNext = progressionService.expToNextLevel(currentExp: 1200)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 1200), 12)
        XCTAssertEqual(expToNext, 0)
    }

    // MARK: - expProgress Tests

    func testExpProgress_0XP_returnsZero() {
        // Given: 0 XP means 0% progress in level 1
        let progress = progressionService.expProgress(currentExp: 0)

        // Then
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }

    func testExpProgress_100XP_level1_returnsHalf() {
        // Given: Level 1 spans 0-199 (200 XP range)
        // 100 XP = 50% progress
        let progress = progressionService.expProgress(currentExp: 100)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 100), 1)
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func testExpProgress_199XP_level1_almostFull() {
        // Given: 199 XP is almost at level 2
        let progress = progressionService.expProgress(currentExp: 199)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 199), 1)
        XCTAssertEqual(progress, 199.0 / 200.0, accuracy: 0.001)
    }

    func testExpProgress_200XP_level2_returnsZero() {
        // Given: Just started level 2 (200-299 range)
        let progress = progressionService.expProgress(currentExp: 200)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 200), 2)
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }

    func testExpProgress_250XP_level2_returnsHalf() {
        // Given: 250 XP is halfway through level 2 (200-299)
        let progress = progressionService.expProgress(currentExp: 250)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 250), 2)
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func testExpProgress_level12_returnsOne() {
        // Given: Max level always shows 100% progress
        let progress = progressionService.expProgress(currentExp: 1200)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 1200), 12)
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    func testExpProgress_level12_excessXP_returnsOne() {
        // Given: Even with excess XP, progress is capped at 100%
        let progress = progressionService.expProgress(currentExp: 9999)

        // Then
        XCTAssertEqual(progressionService.calculateLevel(currentExp: 9999), 12)
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    // MARK: - TDD Consistency Tests

    func testTDD_levelAlwaysConsistentWithExp() {
        // Given: Various XP values
        let testCases: [(xp: Int, expectedLevel: Int)] = [
            (0, 1), (50, 1), (100, 1), (199, 1),
            (200, 2), (299, 2),
            (300, 3), (399, 3),
            (500, 5), (600, 6), (700, 7), (800, 8), (900, 9), (1000, 10), (1100, 11),
            (1200, 12), (1500, 12), (10000, 12)
        ]

        for (xp, expectedLevel) in testCases {
            // When
            let level = progressionService.calculateLevel(currentExp: xp)

            // Then - impossible to have inconsistent state
            XCTAssertEqual(level, expectedLevel, "XP \(xp) should be level \(expectedLevel)")
        }
    }

    func testTDD_expToNextLevelAlwaysCorrect() {
        // Given: Various levels
        for level in 1...12 {
            let xp = level <= 1 ? 0 : level * 100
            let calculatedLevel = progressionService.calculateLevel(currentExp: xp)
            let expToNext = progressionService.expToNextLevel(currentExp: xp)

            // Then
            XCTAssertEqual(calculatedLevel, level)
            if level < 12 {
                XCTAssertEqual(expToNext, (level + 1) * 100)
            } else {
                XCTAssertEqual(expToNext, 0)
            }
        }
    }
}
