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

    func testGetDescription_Dodge_ReturnsNonEmptyDescription() async {
        // Given
        let service = makeService()

        // When
        let description = await service.getDescription(for: .dodge)

        // Then
        XCTAssertFalse(description.isEmpty)
    }

    func testGetDescription_Dodge_MentionsDodging() async {
        // Given
        let service = makeService()

        // When
        let description = await service.getDescription(for: .dodge)

        // Then
        XCTAssertTrue(
            description.lowercased().contains("dodg"),
            "Dodge style description should mention dodging"
        )
    }

    func testGetDescription_Crit_ReturnsNonEmptyDescription() async {
        // Given
        let service = makeService()

        // When
        let description = await service.getDescription(for: .crit)

        // Then
        XCTAssertFalse(description.isEmpty)
    }

    func testGetDescription_Crit_MentionsDamage() async {
        // Given
        let service = makeService()

        // When
        let description = await service.getDescription(for: .crit)

        // Then
        XCTAssertTrue(
            description.lowercased().contains("damage") ||
            description.lowercased().contains("block"),
            "Crit style description should mention damage or blocking"
        )
    }

    func testGetDescription_Def_ReturnsNonEmptyDescription() async {
        // Given
        let service = makeService()

        // When
        let description = await service.getDescription(for: .def)

        // Then
        XCTAssertFalse(description.isEmpty)
    }

    func testGetDescription_Def_MentionsStrengthOrEndurance() async {
        // Given
        let service = makeService()

        // When
        let description = await service.getDescription(for: .def)

        // Then
        XCTAssertTrue(
            description.lowercased().contains("strength") ||
            description.lowercased().contains("endurance") ||
            description.lowercased().contains("combat"),
            "Def style description should mention strength, endurance, or combat"
        )
    }

    func testGetDescription_AllStyles_ReturnsDifferentDescriptions() async {
        // Given
        let service = makeService()

        // When
        let dodgeDesc = await service.getDescription(for: .dodge)
        let critDesc = await service.getDescription(for: .crit)
        let defDesc = await service.getDescription(for: .def)

        // Then
        XCTAssertNotEqual(dodgeDesc, critDesc)
        XCTAssertNotEqual(critDesc, defDesc)
        XCTAssertNotEqual(dodgeDesc, defDesc)
    }

    // MARK: - Get Attribute Bonus Description Tests

    func testGetAttributeBonusDescription_Dodge_MentionsAgility() async {
        // Given
        let service = makeService()

        // When
        let bonus = await service.getAttributeBonusDescription(for: .dodge)

        // Then
        XCTAssertTrue(
            bonus.contains("Agility"),
            "Dodge style should mention Agility bonus"
        )
    }

    func testGetAttributeBonusDescription_Crit_MentionsPower() async {
        // Given
        let service = makeService()

        // When
        let bonus = await service.getAttributeBonusDescription(for: .crit)

        // Then
        XCTAssertTrue(
            bonus.contains("Power"),
            "Crit style should mention Power bonus"
        )
    }

    func testGetAttributeBonusDescription_Def_MentionsEndurance() async {
        // Given
        let service = makeService()

        // When
        let bonus = await service.getAttributeBonusDescription(for: .def)

        // Then
        XCTAssertTrue(
            bonus.contains("Endurance"),
            "Def style should mention Endurance bonus"
        )
    }

    func testGetAttributeBonusDescription_AllStyles_ReturnsDifferentBonuses() async {
        // Given
        let service = makeService()

        // When
        let dodgeBonus = await service.getAttributeBonusDescription(for: .dodge)
        let critBonus = await service.getAttributeBonusDescription(for: .crit)
        let defBonus = await service.getAttributeBonusDescription(for: .def)

        // Then
        XCTAssertNotEqual(dodgeBonus, critBonus)
        XCTAssertNotEqual(critBonus, defBonus)
        XCTAssertNotEqual(dodgeBonus, defBonus)
    }

    func testGetAttributeBonusDescription_ContainsPlusSign() async {
        // Given
        let service = makeService()
        let allStyles: [FightStyle] = [.dodge, .crit, .def]

        for style in allStyles {
            // When
            let bonus = await service.getAttributeBonusDescription(for: style)

            // Then
            XCTAssertTrue(
                bonus.contains("+"),
                "Bonus description for \(style) should contain '+' sign"
            )
        }
    }

    // MARK: - Consistency Tests

    func testGetDescription_ReturnsConsistentResults() async {
        // Given
        let service = makeService()

        // When
        let description1 = await service.getDescription(for: .crit)
        let description2 = await service.getDescription(for: .crit)

        // Then
        XCTAssertEqual(description1, description2)
    }

    func testGetAttributeBonusDescription_ReturnsConsistentResults() async {
        // Given
        let service = makeService()

        // When
        let bonus1 = await service.getAttributeBonusDescription(for: .dodge)
        let bonus2 = await service.getAttributeBonusDescription(for: .dodge)

        // Then
        XCTAssertEqual(bonus1, bonus2)
    }

    // MARK: - Multiple Instance Tests

    func testMultipleInstances_ProduceSameResults() async {
        // Given
        let service1 = makeService()
        let service2 = makeService()

        // When/Then
        for style: FightStyle in [.dodge, .crit, .def] {
            let desc1 = await service1.getDescription(for: style)
            let desc2 = await service2.getDescription(for: style)
            XCTAssertEqual(desc1, desc2)

            let bonus1 = await service1.getAttributeBonusDescription(for: style)
            let bonus2 = await service2.getAttributeBonusDescription(for: style)
            XCTAssertEqual(bonus1, bonus2)
        }
    }
}
