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

    func testBuild_WithAllFieldsSet_ReturnsCharacter() async throws {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setName("TestElf")
        await builder.setFightStyle(.crit)
        let fightStyleAttrs = makeValidAttributes()
        let randomAttrs = HeroAttributes()

        // When
        let character = try await builder.build(
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

    func testBuild_TrimsWhitespaceFromName() async throws {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance2)
        await builder.setName("  Trimmed Name  ")
        await builder.setFightStyle(.dodge)

        // When
        let character = try await builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Then
        XCTAssertEqual(character.name, "Trimmed Name")
    }

    func testBuild_AllFightStyles() async throws {
        // Test all fight styles can be built
        let fightStyles: [FightStyle] = [.crit, .dodge, .def]

        for fightStyle in fightStyles {
            // Given
            let builder = makeBuilder()
            await builder.setAppearance(.appearance1)
            await builder.setName("TestElf")
            await builder.setFightStyle(fightStyle)

            // When
            let character = try await builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )

            // Then
            XCTAssertEqual(character.fightStyle, fightStyle)
        }
    }

    func testBuild_AllAppearances() async throws {
        // Test all appearances can be built
        for appearance in CharacterAppearance.allCases {
            // Given
            let builder = makeBuilder()
            await builder.setAppearance(appearance)
            await builder.setName("TestElf")
            await builder.setFightStyle(.crit)

            // When
            let character = try await builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )

            // Then
            XCTAssertEqual(character.appearance, appearance)
        }
    }

    // MARK: - Missing Fields Tests

    func testBuild_WithoutAppearance_ThrowsMissingAppearance() async {
        // Given
        let builder = makeBuilder()
        await builder.setName("TestElf")
        await builder.setFightStyle(.crit)

        // When/Then
        do {
            _ = try await builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
            XCTFail("Expected CharacterBuilderError.missingAppearance")
        } catch {
            XCTAssertEqual(error as? CharacterBuilderError, .missingAppearance)
        }
    }

    func testBuild_WithoutName_ThrowsMissingName() async {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setFightStyle(.crit)
        // Name not set (empty by default)

        // When/Then
        do {
            _ = try await builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
            XCTFail("Expected CharacterBuilderError.missingName")
        } catch {
            XCTAssertEqual(error as? CharacterBuilderError, .missingName)
        }
    }

    func testBuild_WithEmptyName_ThrowsMissingName() async {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setName("")
        await builder.setFightStyle(.crit)

        // When/Then
        do {
            _ = try await builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
            XCTFail("Expected CharacterBuilderError.missingName")
        } catch {
            XCTAssertEqual(error as? CharacterBuilderError, .missingName)
        }
    }

    func testBuild_WithWhitespaceOnlyName_ThrowsMissingName() async {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setName("   ")
        await builder.setFightStyle(.crit)

        // When/Then
        do {
            _ = try await builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
            XCTFail("Expected CharacterBuilderError.missingName")
        } catch {
            XCTAssertEqual(error as? CharacterBuilderError, .missingName)
        }
    }

    func testBuild_WithoutFightStyle_ThrowsMissingFightStyle() async {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setName("TestElf")
        // Fight style not set

        // When/Then
        do {
            _ = try await builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
            XCTFail("Expected CharacterBuilderError.missingFightStyle")
        } catch {
            XCTAssertEqual(error as? CharacterBuilderError, .missingFightStyle)
        }
    }

    // MARK: - Reset Tests

    func testReset_ClearsAllFields() async {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setName("TestElf")
        await builder.setFightStyle(.crit)

        // When
        await builder.reset()

        // Then: Build should fail because all fields are cleared
        do {
            _ = try await builder.build(
                fightStyleAttributes: makeValidAttributes(),
                randomLevelAttributes: HeroAttributes()
            )
            XCTFail("Expected CharacterBuilderError.missingAppearance")
        } catch {
            // First validation is appearance
            XCTAssertEqual(error as? CharacterBuilderError, .missingAppearance)
        }
    }

    func testReset_AllowsRebuildingWithNewValues() async throws {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setName("FirstElf")
        await builder.setFightStyle(.crit)

        // Build first character
        let firstCharacter = try await builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Reset and set new values
        await builder.reset()
        await builder.setAppearance(.appearance2)
        await builder.setName("SecondElf")
        await builder.setFightStyle(.dodge)

        // When
        let secondCharacter = try await builder.build(
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

    func testBuilder_CanBuildMultipleCharactersWithoutReset() async throws {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setName("TestElf")
        await builder.setFightStyle(.crit)

        // When: Build multiple times without reset
        let character1 = try await builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        let character2 = try await builder.build(
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

    func testBuilder_CanOverwriteValuesBetweenBuilds() async throws {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setName("FirstElf")
        await builder.setFightStyle(.crit)

        // Build first
        _ = try await builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Overwrite values (without reset)
        await builder.setName("UpdatedElf")
        await builder.setFightStyle(.def)

        // When
        let character = try await builder.build(
            fightStyleAttributes: makeValidAttributes(),
            randomLevelAttributes: HeroAttributes()
        )

        // Then
        XCTAssertEqual(character.name, "UpdatedElf")
        XCTAssertEqual(character.fightStyle, .def)
        XCTAssertEqual(character.appearance, .appearance1) // Not changed
    }

    // MARK: - Attributes Tests

    func testBuild_PassesThroughAttributes() async throws {
        // Given
        let builder = makeBuilder()
        await builder.setAppearance(.appearance1)
        await builder.setName("TestElf")
        await builder.setFightStyle(.crit)

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
        let character = try await builder.build(
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
