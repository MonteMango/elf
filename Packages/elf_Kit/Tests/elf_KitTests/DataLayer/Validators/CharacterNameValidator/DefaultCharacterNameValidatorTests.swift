//
//  DefaultCharacterNameValidatorTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for DefaultCharacterNameValidator
///
/// Validation rules:
/// - Name cannot be empty
/// - Minimum length: 2 characters
/// - Maximum length: 30 characters
/// - Only letters and spaces allowed
final class DefaultCharacterNameValidatorTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeValidator() -> DefaultCharacterNameValidator {
        return DefaultCharacterNameValidator()
    }

    // MARK: - Valid Names Tests

    func testValidate_ValidName_ReturnsValid() async {
        // Given
        let validator = makeValidator()
        let validNames = ["Asuna", "Elf Girl", "Frieren", "Ais Wallenstein"]

        for name in validNames {
            // When
            let result = await validator.validate(name)

            // Then
            XCTAssertEqual(result, .valid, "Name '\(name)' should be valid")
            XCTAssertTrue(result.isValid)
            XCTAssertNil(result.errorMessage)
        }
    }

    func testValidate_MinimumLengthName_ReturnsValid() async {
        // Given
        let validator = makeValidator()
        let name = "Ab" // 2 characters

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertEqual(result, .valid)
    }

    func testValidate_MaximumLengthName_ReturnsValid() async {
        // Given
        let validator = makeValidator()
        let name = String(repeating: "A", count: 30)

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertEqual(result, .valid)
    }

    func testValidate_NameWithSpaces_ReturnsValid() async {
        // Given
        let validator = makeValidator()
        let name = "Elf Princess"

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertEqual(result, .valid)
    }

    func testValidate_UnicodeLetters_ReturnsValid() async {
        // Given
        let validator = makeValidator()
        let unicodeNames = ["Élf", "Фриëрен", "エルフ", "Müller"]

        for name in unicodeNames {
            // When
            let result = await validator.validate(name)

            // Then
            XCTAssertEqual(result, .valid, "Unicode name '\(name)' should be valid")
        }
    }

    // MARK: - Empty Name Tests

    func testValidate_EmptyName_ReturnsInvalid() async {
        // Given
        let validator = makeValidator()
        let name = ""

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
        if case .invalid(let reason) = result {
            XCTAssertTrue(reason.lowercased().contains("empty"))
        }
    }

    func testValidate_WhitespaceOnlyName_ReturnsInvalid() async {
        // Given
        let validator = makeValidator()
        let whitespaceNames = [" ", "   ", "\t", "\n", "  \t  "]

        for name in whitespaceNames {
            // When
            let result = await validator.validate(name)

            // Then
            XCTAssertFalse(result.isValid, "Whitespace-only name should be invalid")
        }
    }

    // MARK: - Length Tests

    func testValidate_TooShortName_ReturnsInvalid() async {
        // Given
        let validator = makeValidator()
        let name = "A" // Only 1 character

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
        if case .invalid(let reason) = result {
            XCTAssertTrue(reason.contains("2"), "Error should mention minimum length")
        }
    }

    func testValidate_TooLongName_ReturnsInvalid() async {
        // Given
        let validator = makeValidator()
        let name = String(repeating: "A", count: 31) // 31 characters

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
        if case .invalid(let reason) = result {
            XCTAssertTrue(reason.contains("30"), "Error should mention maximum length")
        }
    }

    func testValidate_VeryLongName_ReturnsInvalid() async {
        // Given
        let validator = makeValidator()
        let name = String(repeating: "A", count: 100)

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - Invalid Characters Tests

    func testValidate_NameWithNumbers_ReturnsInvalid() async {
        // Given
        let validator = makeValidator()
        let name = "Elf123"

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertFalse(result.isValid)
        if case .invalid(let reason) = result {
            XCTAssertTrue(reason.lowercased().contains("letters"))
        }
    }

    func testValidate_NameWithSpecialCharacters_ReturnsInvalid() async {
        // Given
        let validator = makeValidator()
        let invalidNames = ["Elf@Girl", "Elf#1", "Elf-Princess", "Elf_Hero", "Elf!"]

        for name in invalidNames {
            // When
            let result = await validator.validate(name)

            // Then
            XCTAssertFalse(result.isValid, "Name '\(name)' with special characters should be invalid")
        }
    }

    func testValidate_NameWithPunctuation_ReturnsInvalid() async {
        // Given
        let validator = makeValidator()
        let punctuationNames = ["Elf.", "Elf,", "Elf:", "Elf;", "Elf'"]

        for name in punctuationNames {
            // When
            let result = await validator.validate(name)

            // Then
            XCTAssertFalse(result.isValid, "Name '\(name)' with punctuation should be invalid")
        }
    }

    // MARK: - Whitespace Trimming Tests

    func testValidate_TrimsLeadingWhitespace() async {
        // Given
        let validator = makeValidator()
        let name = "   ValidName"

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertEqual(result, .valid, "Name should be valid after trimming leading whitespace")
    }

    func testValidate_TrimsTrailingWhitespace() async {
        // Given
        let validator = makeValidator()
        let name = "ValidName   "

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertEqual(result, .valid, "Name should be valid after trimming trailing whitespace")
    }

    func testValidate_TrimsThenChecksLength() async {
        // Given
        let validator = makeValidator()
        // "A" + spaces = after trim only 1 character
        let name = "A   "

        // When
        let result = await validator.validate(name)

        // Then
        XCTAssertFalse(result.isValid, "After trimming, name is too short")
    }

    // MARK: - NameValidationResult Tests

    func testNameValidationResult_Valid_HasCorrectProperties() {
        // Given
        let result = NameValidationResult.valid

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testNameValidationResult_Invalid_HasCorrectProperties() {
        // Given
        let reason = "Test error message"
        let result = NameValidationResult.invalid(reason: reason)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, reason)
    }

    func testNameValidationResult_Equatable() {
        // Given
        let valid1 = NameValidationResult.valid
        let valid2 = NameValidationResult.valid
        let invalid1 = NameValidationResult.invalid(reason: "Error")
        let invalid2 = NameValidationResult.invalid(reason: "Error")
        let invalid3 = NameValidationResult.invalid(reason: "Different error")

        // Then
        XCTAssertEqual(valid1, valid2)
        XCTAssertEqual(invalid1, invalid2)
        XCTAssertNotEqual(valid1, invalid1)
        XCTAssertNotEqual(invalid1, invalid3)
    }
}
