//
//  ElfRandomBotAITests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for ElfRandomBotAI
///
/// Bot AI randomly selects body parts for attack and defense based on count:
/// - Attack points: 1 (single weapon) or 2 (dual wield)
/// - Defense points: 2 (base) or 3 (with shield)
final class ElfRandomBotAITests: XCTestCase {

    // MARK: - Test Helpers

    private let botAI = ElfRandomBotAI()

    // MARK: - Attack Points Tests

    func testSelectAttackPoints_SinglePoint_ReturnsOnePoint() async {
        // Given
        let count = 1

        // When
        let attackPoints = await botAI.selectAttackPoints(count: count)

        // Then
        XCTAssertEqual(attackPoints.count, 1, "Should return exactly 1 attack point")
    }

    func testSelectAttackPoints_TwoPoints_ReturnsTwoPoints() async {
        // Given
        let count = 2

        // When
        let attackPoints = await botAI.selectAttackPoints(count: count)

        // Then
        XCTAssertEqual(attackPoints.count, 2, "Should return exactly 2 attack points")
    }

    func testSelectAttackPoints_ReturnsValidBodyParts() async {
        // Given
        let validBodyParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]

        // When
        let attackPoints = await botAI.selectAttackPoints(count: 2)

        // Then
        for bodyPart in attackPoints {
            XCTAssertTrue(validBodyParts.contains(bodyPart),
                         "\(bodyPart) should be a valid body part")
        }
    }

    func testSelectAttackPoints_IsRandom() async {
        // Given
        var selectedPoints: [Set<BodyPart>] = []

        // When: Run multiple times
        for _ in 0..<50 {
            let points = await botAI.selectAttackPoints(count: 2)
            selectedPoints.append(points)
        }

        // Then: Should have some variety (not all the same)
        let uniqueSelections = Set(selectedPoints.map { $0.hashValue })
        XCTAssertGreaterThan(uniqueSelections.count, 1,
                            "Should select different body parts over multiple runs")
    }

    func testSelectAttackPoints_ZeroCount_ReturnsEmpty() async {
        // When
        let attackPoints = await botAI.selectAttackPoints(count: 0)

        // Then
        XCTAssertTrue(attackPoints.isEmpty, "Should return empty set for count 0")
    }

    // MARK: - Defense Points Tests

    func testSelectDefensePoints_TwoPoints_ReturnsTwoPoints() async {
        // Given
        let count = 2

        // When
        let defensePoints = await botAI.selectDefensePoints(count: count)

        // Then
        XCTAssertEqual(defensePoints.count, 2, "Should return exactly 2 defense points")
    }

    func testSelectDefensePoints_ThreePoints_ReturnsThreePoints() async {
        // Given
        let count = 3

        // When
        let defensePoints = await botAI.selectDefensePoints(count: count)

        // Then
        XCTAssertEqual(defensePoints.count, 3, "Should return exactly 3 defense points")
    }

    func testSelectDefensePoints_ReturnsValidBodyParts() async {
        // Given
        let validBodyParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]

        // When
        let defensePoints = await botAI.selectDefensePoints(count: 3)

        // Then
        for bodyPart in defensePoints {
            XCTAssertTrue(validBodyParts.contains(bodyPart),
                         "\(bodyPart) should be a valid body part")
        }
    }

    func testSelectDefensePoints_IsRandom() async {
        // Given
        var selectedPoints: [Set<BodyPart>] = []

        // When: Run multiple times
        for _ in 0..<50 {
            let points = await botAI.selectDefensePoints(count: 3)
            selectedPoints.append(points)
        }

        // Then: Should have some variety
        let uniqueSelections = Set(selectedPoints.map { $0.hashValue })
        XCTAssertGreaterThan(uniqueSelections.count, 1,
                            "Should select different body parts over multiple runs")
    }

    // MARK: - All Body Parts Can Be Selected

    func testAllBodyPartsCanBeSelected_Attack() async {
        // Given
        var allSelectedParts: Set<BodyPart> = []

        // When: Run many times to collect all possible selections
        for _ in 0..<100 {
            let points = await botAI.selectAttackPoints(count: 2)
            allSelectedParts.formUnion(points)
        }

        // Then: All 5 body parts should have been selected at least once
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(allSelectedParts, expectedParts,
                      "All body parts should be selectable for attack")
    }

    func testAllBodyPartsCanBeSelected_Defense() async {
        // Given
        var allSelectedParts: Set<BodyPart> = []

        // When: Run many times to collect all possible selections
        for _ in 0..<100 {
            let points = await botAI.selectDefensePoints(count: 3)
            allSelectedParts.formUnion(points)
        }

        // Then: All 5 body parts should have been selected at least once
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(allSelectedParts, expectedParts,
                      "All body parts should be selectable for defense")
    }

    // MARK: - Edge Cases

    func testSelectAttackPoints_MaxCount_ReturnsFivePoints() async {
        // When
        let attackPoints = await botAI.selectAttackPoints(count: 5)

        // Then
        XCTAssertEqual(attackPoints.count, 5, "Should return all 5 body parts")
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(attackPoints, expectedParts, "Should contain all body parts")
    }

    func testSelectDefensePoints_MaxCount_ReturnsFivePoints() async {
        // When
        let defensePoints = await botAI.selectDefensePoints(count: 5)

        // Then
        XCTAssertEqual(defensePoints.count, 5, "Should return all 5 body parts")
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(defensePoints, expectedParts, "Should contain all body parts")
    }

    func testSelectAttackPoints_ExceedingMaxCount_ReturnsOnlyFive() async {
        // When: Request more than available body parts
        let attackPoints = await botAI.selectAttackPoints(count: 10)

        // Then: Should cap at 5 (total body parts)
        XCTAssertEqual(attackPoints.count, 5, "Should not exceed total body parts count")
    }
}
