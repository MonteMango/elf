//
//  DefaultFightStyleDescriptionServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for DefaultFightStyleDescriptionService
///
/// Service provides:
/// - Tactical descriptions for each fight style
/// - Attribute bonus descriptions for each fight style
final class DefaultFightStyleDescriptionServiceTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeService() -> DefaultFightStyleDescriptionService {
        return DefaultFightStyleDescriptionService()
    }

    // MARK: - Get Description Tests

    func testGetDescription_Dodge_ReturnsNonEmptyDescription() {
        // Given
        let service = makeService()

        // When
        let description = service.getDescription(for: .dodge)

        // Then
        XCTAssertFalse(description.isEmpty)
    }

    func testGetDescription_Dodge_MentionsDodging() {
        // Given
        let service = makeService()

        // When
        let description = service.getDescription(for: .dodge)

        // Then
        XCTAssertTrue(
            description.lowercased().contains("dodg"),
            "Dodge style description should mention dodging"
        )
    }

    func testGetDescription_Crit_ReturnsNonEmptyDescription() {
        // Given
        let service = makeService()

        // When
        let description = service.getDescription(for: .crit)

        // Then
        XCTAssertFalse(description.isEmpty)
    }

    func testGetDescription_Crit_MentionsDamage() {
        // Given
        let service = makeService()

        // When
        let description = service.getDescription(for: .crit)

        // Then
        XCTAssertTrue(
            description.lowercased().contains("damage") ||
            description.lowercased().contains("block"),
            "Crit style description should mention damage or blocking"
        )
    }

    func testGetDescription_Def_ReturnsNonEmptyDescription() {
        // Given
        let service = makeService()

        // When
        let description = service.getDescription(for: .def)

        // Then
        XCTAssertFalse(description.isEmpty)
    }

    func testGetDescription_Def_MentionsStrengthOrEndurance() {
        // Given
        let service = makeService()

        // When
        let description = service.getDescription(for: .def)

        // Then
        XCTAssertTrue(
            description.lowercased().contains("strength") ||
            description.lowercased().contains("endurance") ||
            description.lowercased().contains("combat"),
            "Def style description should mention strength, endurance, or combat"
        )
    }

    func testGetDescription_AllStyles_ReturnsDifferentDescriptions() {
        // Given
        let service = makeService()

        // When
        let dodgeDesc = service.getDescription(for: .dodge)
        let critDesc = service.getDescription(for: .crit)
        let defDesc = service.getDescription(for: .def)

        // Then
        XCTAssertNotEqual(dodgeDesc, critDesc)
        XCTAssertNotEqual(critDesc, defDesc)
        XCTAssertNotEqual(dodgeDesc, defDesc)
    }

    // MARK: - Get Attribute Bonus Description Tests

    func testGetAttributeBonusDescription_Dodge_MentionsAgility() {
        // Given
        let service = makeService()

        // When
        let bonus = service.getAttributeBonusDescription(for: .dodge)

        // Then
        XCTAssertTrue(
            bonus.contains("Agility"),
            "Dodge style should mention Agility bonus"
        )
    }

    func testGetAttributeBonusDescription_Crit_MentionsPower() {
        // Given
        let service = makeService()

        // When
        let bonus = service.getAttributeBonusDescription(for: .crit)

        // Then
        XCTAssertTrue(
            bonus.contains("Power"),
            "Crit style should mention Power bonus"
        )
    }

    func testGetAttributeBonusDescription_Def_MentionsStrength() {
        // Given
        let service = makeService()

        // When
        let bonus = service.getAttributeBonusDescription(for: .def)

        // Then
        XCTAssertTrue(
            bonus.contains("Strength"),
            "Def style should mention Strength bonus"
        )
    }

    func testGetAttributeBonusDescription_AllStyles_ReturnsDifferentBonuses() {
        // Given
        let service = makeService()

        // When
        let dodgeBonus = service.getAttributeBonusDescription(for: .dodge)
        let critBonus = service.getAttributeBonusDescription(for: .crit)
        let defBonus = service.getAttributeBonusDescription(for: .def)

        // Then
        XCTAssertNotEqual(dodgeBonus, critBonus)
        XCTAssertNotEqual(critBonus, defBonus)
        XCTAssertNotEqual(dodgeBonus, defBonus)
    }

    func testGetAttributeBonusDescription_ContainsPlusSign() {
        // Given
        let service = makeService()
        let allStyles: [FightStyle] = [.dodge, .crit, .def]

        for style in allStyles {
            // When
            let bonus = service.getAttributeBonusDescription(for: style)

            // Then
            XCTAssertTrue(
                bonus.contains("+"),
                "Bonus description for \(style) should contain '+' sign"
            )
        }
    }

    // MARK: - Consistency Tests

    func testGetDescription_ReturnsConsistentResults() {
        // Given
        let service = makeService()

        // When
        let description1 = service.getDescription(for: .crit)
        let description2 = service.getDescription(for: .crit)

        // Then
        XCTAssertEqual(description1, description2)
    }

    func testGetAttributeBonusDescription_ReturnsConsistentResults() {
        // Given
        let service = makeService()

        // When
        let bonus1 = service.getAttributeBonusDescription(for: .dodge)
        let bonus2 = service.getAttributeBonusDescription(for: .dodge)

        // Then
        XCTAssertEqual(bonus1, bonus2)
    }

    // MARK: - Multiple Instance Tests

    func testMultipleInstances_ProduceSameResults() {
        // Given
        let service1 = makeService()
        let service2 = makeService()

        // When/Then
        for style: FightStyle in [.dodge, .crit, .def] {
            XCTAssertEqual(
                service1.getDescription(for: style),
                service2.getDescription(for: style)
            )
            XCTAssertEqual(
                service1.getAttributeBonusDescription(for: style),
                service2.getAttributeBonusDescription(for: style)
            )
        }
    }
}
