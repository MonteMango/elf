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
/// Bot AI randomly selects body parts for attack and defense based on hero's equipment:
/// - Attack points: 1 (single weapon) or 2 (dual wield)
/// - Defense points: 2 (base) or 3 (with shield)
final class ElfRandomBotAITests: XCTestCase {

    // MARK: - Test Helpers

    private let botAI = ElfRandomBotAI()

    private func makeHero(
        hasDualWeapons: Bool = false,
        hasShield: Bool = false
    ) -> ElfHero {
        return ElfHero(
            level: 1,
            fightStyleAttributes: HeroAttributes(hitPoints: 100),
            randomLevelAttributes: HeroAttributes(),
            leftHandWeaponElfItem: hasDualWeapons ? makeMockWeapon() : nil,
            rightHandWeaponElfItem: makeMockWeapon(),
            shieldElfItem: hasShield ? makeMockShield() : nil
        )
    }

    private func makeMockWeapon() -> ElfWeaponItem {
        let weaponItem = WeaponItem.mock(
            id: UUID(),
            title: "Test Sword",
            tier: 1,
            minimumAttackPoint: 5,
            maximumAttackPoint: 10,
            handUse: .primary
        )
        return ElfWeaponItem(weaponItem: weaponItem)
    }

    private func makeMockShield() -> ElfShieldItem {
        let shieldItem = ShieldItem.mock(
            id: UUID(),
            title: "Test Shield",
            tier: 1,
            physicalDefensePoint: 5
        )
        return ElfShieldItem(shieldItem: shieldItem)
    }

    // MARK: - Attack Points Tests

    func testSelectAttackPoints_SingleWeapon_ReturnsOnePoint() {
        // Given
        let hero = makeHero(hasDualWeapons: false, hasShield: false)
        XCTAssertEqual(hero.atackPointsAmount, 1)

        // When
        let attackPoints = botAI.selectAttackPoints(for: hero)

        // Then
        XCTAssertEqual(attackPoints.count, 1, "Single weapon should give 1 attack point")
    }

    func testSelectAttackPoints_DualWield_ReturnsTwoPoints() {
        // Given
        let hero = makeHero(hasDualWeapons: true, hasShield: false)
        XCTAssertEqual(hero.atackPointsAmount, 2)

        // When
        let attackPoints = botAI.selectAttackPoints(for: hero)

        // Then
        XCTAssertEqual(attackPoints.count, 2, "Dual wield should give 2 attack points")
    }

    func testSelectAttackPoints_ReturnsValidBodyParts() {
        // Given
        let hero = makeHero()
        let validBodyParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]

        // When
        let attackPoints = botAI.selectAttackPoints(for: hero)

        // Then
        for bodyPart in attackPoints {
            XCTAssertTrue(validBodyParts.contains(bodyPart),
                         "\(bodyPart) should be a valid body part")
        }
    }

    func testSelectAttackPoints_IsRandom() {
        // Given
        let hero = makeHero(hasDualWeapons: true)
        var selectedPoints: [Set<BodyPart>] = []

        // When: Run multiple times
        for _ in 0..<50 {
            let points = botAI.selectAttackPoints(for: hero)
            selectedPoints.append(points)
        }

        // Then: Should have some variety (not all the same)
        let uniqueSelections = Set(selectedPoints.map { $0.hashValue })
        XCTAssertGreaterThan(uniqueSelections.count, 1,
                            "Should select different body parts over multiple runs")
    }

    // MARK: - Defense Points Tests

    func testSelectDefensePoints_NoShield_ReturnsTwoPoints() {
        // Given
        let hero = makeHero(hasShield: false)
        XCTAssertEqual(hero.defensePointsAmount, 2)

        // When
        let defensePoints = botAI.selectDefensePoints(for: hero)

        // Then
        XCTAssertEqual(defensePoints.count, 2, "No shield should give 2 defense points")
    }

    func testSelectDefensePoints_WithShield_ReturnsThreePoints() {
        // Given
        let hero = makeHero(hasShield: true)
        XCTAssertEqual(hero.defensePointsAmount, 3)

        // When
        let defensePoints = botAI.selectDefensePoints(for: hero)

        // Then
        XCTAssertEqual(defensePoints.count, 3, "Shield should give 3 defense points")
    }

    func testSelectDefensePoints_ReturnsValidBodyParts() {
        // Given
        let hero = makeHero(hasShield: true)
        let validBodyParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]

        // When
        let defensePoints = botAI.selectDefensePoints(for: hero)

        // Then
        for bodyPart in defensePoints {
            XCTAssertTrue(validBodyParts.contains(bodyPart),
                         "\(bodyPart) should be a valid body part")
        }
    }

    func testSelectDefensePoints_IsRandom() {
        // Given
        let hero = makeHero(hasShield: true)
        var selectedPoints: [Set<BodyPart>] = []

        // When: Run multiple times
        for _ in 0..<50 {
            let points = botAI.selectDefensePoints(for: hero)
            selectedPoints.append(points)
        }

        // Then: Should have some variety
        let uniqueSelections = Set(selectedPoints.map { $0.hashValue })
        XCTAssertGreaterThan(uniqueSelections.count, 1,
                            "Should select different body parts over multiple runs")
    }

    // MARK: - All Body Parts Can Be Selected

    func testAllBodyPartsCanBeSelected_Attack() {
        // Given
        let hero = makeHero(hasDualWeapons: true)
        var allSelectedParts: Set<BodyPart> = []

        // When: Run many times to collect all possible selections
        for _ in 0..<100 {
            let points = botAI.selectAttackPoints(for: hero)
            allSelectedParts.formUnion(points)
        }

        // Then: All 5 body parts should have been selected at least once
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(allSelectedParts, expectedParts,
                      "All body parts should be selectable for attack")
    }

    func testAllBodyPartsCanBeSelected_Defense() {
        // Given
        let hero = makeHero(hasShield: true)
        var allSelectedParts: Set<BodyPart> = []

        // When: Run many times to collect all possible selections
        for _ in 0..<100 {
            let points = botAI.selectDefensePoints(for: hero)
            allSelectedParts.formUnion(points)
        }

        // Then: All 5 body parts should have been selected at least once
        let expectedParts: Set<BodyPart> = [.head, .body, .leftHand, .rightHand, .legs]
        XCTAssertEqual(allSelectedParts, expectedParts,
                      "All body parts should be selectable for defense")
    }
}

// MARK: - Mock Extensions

private extension WeaponItem {
    static func mock(
        id: UUID,
        title: String,
        tier: Int16,
        minimumAttackPoint: Int16,
        maximumAttackPoint: Int16,
        handUse: WeaponHandUse
    ) -> WeaponItem {
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "\(title)",
            "tier": \(tier),
            "minimumAttackPoint": \(minimumAttackPoint),
            "maximumAttackPoint": \(maximumAttackPoint),
            "handUse": "\(handUse.rawValue)"
        }
        """
        return try! JSONDecoder().decode(WeaponItem.self, from: Data(json.utf8))
    }
}

private extension ShieldItem {
    static func mock(
        id: UUID,
        title: String,
        tier: Int16,
        physicalDefensePoint: Int16
    ) -> ShieldItem {
        let json = """
        {
            "id": "\(id.uuidString)",
            "title": "\(title)",
            "tier": \(tier),
            "physicalDefensePoint": \(physicalDefensePoint)
        }
        """
        return try! JSONDecoder().decode(ShieldItem.self, from: Data(json.utf8))
    }
}
