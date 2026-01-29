//
//  DefaultCharacterBuilderTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for DefaultCharacterBuilder
///
/// Builder validates:
/// - Appearance must be set
/// - Name must be non-empty (after trimming)
/// - Fight style must be set
@MainActor
final class DefaultCharacterBuilderTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeBuilder() -> DefaultCharacterBuilder {
        return DefaultCharacterBuilder()
    }

    private func makeValidAttributes() -> HeroAttributes {
        return HeroAttributes(
            hitPoints: 100,
            manaPoints: 50,
            agility: 10,
            strength: 10,
            power: 10,
            instinct: 10
        )
    }

    // MARK: - Successful Build Tests

    func testBuild_WithAllFieldsSet_ReturnsCharacter() throws {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setName("TestElf")
        builder.setFightStyle(.crit)
        let fightStyleAttrs = makeValidAttributes()
        let randomAttrs = HeroAttributes()

        // When
        let character = try builder.build(
            fightStyleAttributes: fightStyleAttrs,
            randomLevelAttributes: randomAttrs
        )

        // Then
        XCTAssertEqual(character.name, "TestElf")
        XCTAssertEqual(character.appearance, .appearance1)
        XCTAssertEqual(character.fightStyle, .crit)
        XCTAssertEqual(character.fightStyleAttributes.hitPoints, 100)
        XCTAssertEqual(character.fightStyleAttributes.agility, 10)
    }

    func testBuild_TrimsWhitespaceFromName() throws {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance2)
        builder.setName("  Trimmed Name  ")
        builder.setFightStyle(.dodge)

        // When
        let character = try builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Then
        XCTAssertEqual(character.name, "Trimmed Name")
    }

    func testBuild_AllFightStyles() throws {
        // Test all fight styles can be built
        let fightStyles: [FightStyle] = [.crit, .dodge, .def]

        for fightStyle in fightStyles {
            // Given
            let builder = makeBuilder()
            builder.setAppearance(.appearance1)
            builder.setName("TestElf")
            builder.setFightStyle(fightStyle)

            // When
            let character = try builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )

            // Then
            XCTAssertEqual(character.fightStyle, fightStyle)
        }
    }

    func testBuild_AllAppearances() throws {
        // Test all appearances can be built
        for appearance in CharacterAppearance.allCases {
            // Given
            let builder = makeBuilder()
            builder.setAppearance(appearance)
            builder.setName("TestElf")
            builder.setFightStyle(.crit)

            // When
            let character = try builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )

            // Then
            XCTAssertEqual(character.appearance, appearance)
        }
    }

    // MARK: - Missing Fields Tests

    func testBuild_WithoutAppearance_ThrowsMissingAppearance() {
        // Given
        let builder = makeBuilder()
        builder.setName("TestElf")
        builder.setFightStyle(.crit)

        // When/Then
        XCTAssertThrowsError(
            try builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
        ) { error in
            XCTAssertEqual(error as? CharacterBuilderError, .missingAppearance)
        }
    }

    func testBuild_WithoutName_ThrowsMissingName() {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setFightStyle(.crit)
        // Name not set (empty by default)

        // When/Then
        XCTAssertThrowsError(
            try builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
        ) { error in
            XCTAssertEqual(error as? CharacterBuilderError, .missingName)
        }
    }

    func testBuild_WithEmptyName_ThrowsMissingName() {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setName("")
        builder.setFightStyle(.crit)

        // When/Then
        XCTAssertThrowsError(
            try builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
        ) { error in
            XCTAssertEqual(error as? CharacterBuilderError, .missingName)
        }
    }

    func testBuild_WithWhitespaceOnlyName_ThrowsMissingName() {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setName("   ")
        builder.setFightStyle(.crit)

        // When/Then
        XCTAssertThrowsError(
            try builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
        ) { error in
            XCTAssertEqual(error as? CharacterBuilderError, .missingName)
        }
    }

    func testBuild_WithoutFightStyle_ThrowsMissingFightStyle() {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setName("TestElf")
        // Fight style not set

        // When/Then
        XCTAssertThrowsError(
            try builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
        ) { error in
            XCTAssertEqual(error as? CharacterBuilderError, .missingFightStyle)
        }
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllFields() {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setName("TestElf")
        builder.setFightStyle(.crit)

        // When
        builder.reset()

        // Then: Build should fail because all fields are cleared
        XCTAssertThrowsError(
            try builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
        ) { error in
            // First validation is appearance
            XCTAssertEqual(error as? CharacterBuilderError, .missingAppearance)
        }
    }

    func testReset_AllowsRebuildingWithNewValues() throws {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setName("FirstElf")
        builder.setFightStyle(.crit)

        // Build first character
        let firstCharacter = try builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Reset and set new values
        builder.reset()
        builder.setAppearance(.appearance2)
        builder.setName("SecondElf")
        builder.setFightStyle(.dodge)

        // When
        let secondCharacter = try builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Then
        XCTAssertEqual(firstCharacter.name, "FirstElf")
        XCTAssertEqual(firstCharacter.appearance, .appearance1)
        XCTAssertEqual(firstCharacter.fightStyle, .crit)

        XCTAssertEqual(secondCharacter.name, "SecondElf")
        XCTAssertEqual(secondCharacter.appearance, .appearance2)
        XCTAssertEqual(secondCharacter.fightStyle, .dodge)
    }

    // MARK: - Reusability Tests

    func testBuilder_CanBuildMultipleCharactersWithoutReset() throws {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setName("TestElf")
        builder.setFightStyle(.crit)

        // When: Build multiple times without reset
        let character1 = try builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        let character2 = try builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Then: Both should succeed with same values
        XCTAssertEqual(character1.name, character2.name)
        XCTAssertEqual(character1.appearance, character2.appearance)
        XCTAssertEqual(character1.fightStyle, character2.fightStyle)
        // But should have different IDs
        XCTAssertNotEqual(character1.id, character2.id)
    }

    func testBuilder_CanOverwriteValuesBetweenBuilds() throws {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setName("FirstElf")
        builder.setFightStyle(.crit)

        // Build first
        _ = try builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Overwrite values (without reset)
        builder.setName("UpdatedElf")
        builder.setFightStyle(.def)

        // When
        let character = try builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Then
        XCTAssertEqual(character.name, "UpdatedElf")
        XCTAssertEqual(character.fightStyle, .def)
        XCTAssertEqual(character.appearance, .appearance1) // Not changed
    }

    // MARK: - Attributes Tests

    func testBuild_PassesThroughAttributes() throws {
        // Given
        let builder = makeBuilder()
        builder.setAppearance(.appearance1)
        builder.setName("TestElf")
        builder.setFightStyle(.crit)

        let fightStyleAttrs = HeroAttributes(
            hitPoints: 120,
            manaPoints: 60,
            agility: 15,
            strength: 20,
            power: 25,
            instinct: 10
        )
        let randomAttrs = HeroAttributes(
            hitPoints: 10,
            manaPoints: 5,
            agility: 2,
            strength: 3,
            power: 1,
            instinct: 4
        )

        // When
        let character = try builder.build(
            fightStyleAttributes: fightStyleAttrs,
            randomLevelAttributes: randomAttrs
        )

        // Then
        XCTAssertEqual(character.fightStyleAttributes.hitPoints, 120)
        XCTAssertEqual(character.fightStyleAttributes.power, 25)
        XCTAssertEqual(character.randomLevelAttributes.hitPoints, 10)
        XCTAssertEqual(character.randomLevelAttributes.strength, 3)
    }

    // MARK: - Error Description Tests

    func testCharacterBuilderError_HasLocalizedDescriptions() {
        // Given
        let errors: [CharacterBuilderError] = [
            .missingAppearance,
            .missingName,
            .missingFightStyle
        ]

        // Then: All errors should have non-empty descriptions
        for error in errors {
            XCTAssertFalse(
                error.localizedDescription.isEmpty,
                "Error \(error) should have a localized description"
            )
        }
    }
}
