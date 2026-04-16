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

    func testSelectAttackPoints_SinglePoint_ReturnsOnePoint() {
        let count = 1
        let attackPoints = botAI.selectAttackPoints(count: count)
        XCTAssertEqual(attackPoints.count, 1, "Should return exactly 1 attack point")
    }

    func testSelectAttackPoints_TwoPoints_ReturnsTwoPoints() {
        let count = 2
        let attackPoints = botAI.selectAttackPoints(count: count)
        XCTAssertEqual(attackPoints.count, 2, "Should return exactly 2 attack points")
    }

    func testSelectAttackPoints_ReturnsValidBodyParts() {
        let validBodyParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        let attackPoints = botAI.selectAttackPoints(count: 2)
        for bodyPart in attackPoints {
            XCTAssertTrue(validBodyParts.contains(bodyPart),
                         "\(bodyPart) should be a valid body part")
        }
    }

    func testSelectAttackPoints_IsRandom() {
        var selectedPoints: [Set<BodyPart>] = []
        for _ in 0..<50 {
            let points = botAI.selectAttackPoints(count: 2)
            selectedPoints.append(points)
        }
        let uniqueSelections = Set(selectedPoints.map { $0.hashValue })
        XCTAssertGreaterThan(uniqueSelections.count, 1,
                            "Should select different body parts over multiple runs")
    }

    func testSelectAttackPoints_ZeroCount_ReturnsEmpty() {
        let attackPoints = botAI.selectAttackPoints(count: 0)
        XCTAssertTrue(attackPoints.isEmpty, "Should return empty set for count 0")
    }

    // MARK: - Defense Points Tests

    func testSelectDefensePoints_TwoPoints_ReturnsTwoPoints() {
        let count = 2
        let defensePoints = botAI.selectDefensePoints(count: count)
        XCTAssertEqual(defensePoints.count, 2, "Should return exactly 2 defense points")
    }

    func testSelectDefensePoints_ThreePoints_ReturnsThreePoints() {
        let count = 3
        let defensePoints = botAI.selectDefensePoints(count: count)
        XCTAssertEqual(defensePoints.count, 3, "Should return exactly 3 defense points")
    }

    func testSelectDefensePoints_ReturnsValidBodyParts() {
        let validBodyParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        let defensePoints = botAI.selectDefensePoints(count: 3)
        for bodyPart in defensePoints {
            XCTAssertTrue(validBodyParts.contains(bodyPart),
                         "\(bodyPart) should be a valid body part")
        }
    }

    func testSelectDefensePoints_IsRandom() {
        var selectedPoints: [Set<BodyPart>] = []
        for _ in 0..<50 {
            let points = botAI.selectDefensePoints(count: 3)
            selectedPoints.append(points)
        }
        let uniqueSelections = Set(selectedPoints.map { $0.hashValue })
        XCTAssertGreaterThan(uniqueSelections.count, 1,
                            "Should select different body parts over multiple runs")
    }

    // MARK: - All Body Parts Can Be Selected

    func testAllBodyPartsCanBeSelected_Attack() {
        var allSelectedParts: Set<BodyPart> = []
        for _ in 0..<100 {
            let points = botAI.selectAttackPoints(count: 2)
            allSelectedParts.formUnion(points)
        }
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(allSelectedParts, expectedParts,
                      "All body parts should be selectable for attack")
    }

    func testAllBodyPartsCanBeSelected_Defense() {
        var allSelectedParts: Set<BodyPart> = []
        for _ in 0..<100 {
            let points = botAI.selectDefensePoints(count: 3)
            allSelectedParts.formUnion(points)
        }
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(allSelectedParts, expectedParts,
                      "All body parts should be selectable for defense")
    }

    // MARK: - Edge Cases

    func testSelectAttackPoints_MaxCount_ReturnsFivePoints() {
        let attackPoints = botAI.selectAttackPoints(count: 5)
        XCTAssertEqual(attackPoints.count, 5, "Should return all 5 body parts")
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(attackPoints, expectedParts, "Should contain all body parts")
    }

    func testSelectDefensePoints_MaxCount_ReturnsFivePoints() {
        let defensePoints = botAI.selectDefensePoints(count: 5)
        XCTAssertEqual(defensePoints.count, 5, "Should return all 5 body parts")
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(defensePoints, expectedParts, "Should contain all body parts")
    }

    func testSelectAttackPoints_ExceedingMaxCount_ReturnsOnlyFive() {
        let attackPoints = botAI.selectAttackPoints(count: 10)
        XCTAssertEqual(attackPoints.count, 5, "Should not exceed total body parts count")
    }
}
