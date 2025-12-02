//
//  DefaultCharacterNameSuggestionServiceTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import XCTest
@testable import elf_Kit

/// Tests for DefaultCharacterNameSuggestionService
///
/// Service provides:
/// - Random name generation from predefined list
/// - Full list of name suggestions
final class DefaultCharacterNameSuggestionServiceTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeService() -> DefaultCharacterNameSuggestionService {
        return DefaultCharacterNameSuggestionService()
    }

    // MARK: - Generate Random Name Tests

    func testGenerateRandomName_ReturnsNonEmptyString() {
        // Given
        let service = makeService()

        // When
        let name = service.generateRandomName()

        // Then
        XCTAssertFalse(name.isEmpty)
    }

    func testGenerateRandomName_ReturnsNameFromSuggestions() {
        // Given
        let service = makeService()
        let allSuggestions = service.getAllSuggestions()

        // When
        let name = service.generateRandomName()

        // Then
        XCTAssertTrue(
            allSuggestions.contains(name),
            "Generated name '\(name)' should be in the suggestions list"
        )
    }

    func testGenerateRandomName_ProducesVariety() {
        // Given
        let service = makeService()
        var generatedNames: Set<String> = []

        // When: Generate many names
        for _ in 0..<100 {
            let name = service.generateRandomName()
            generatedNames.insert(name)
        }

        // Then: Should have some variety
        XCTAssertGreaterThan(
            generatedNames.count,
            1,
            "Should generate different names over multiple calls"
        )
    }

    func testGenerateRandomName_AllNamesCanBeGenerated() {
        // Given
        let service = makeService()
        let allSuggestions = Set(service.getAllSuggestions())
        var generatedNames: Set<String> = []

        // When: Generate many names
        for _ in 0..<1000 {
            let name = service.generateRandomName()
            generatedNames.insert(name)

            // Early exit if all names found
            if generatedNames == allSuggestions {
                break
            }
        }

        // Then: Should eventually generate all names
        XCTAssertEqual(
            generatedNames,
            allSuggestions,
            "All suggestion names should be generatable"
        )
    }

    // MARK: - Get All Suggestions Tests

    func testGetAllSuggestions_ReturnsNonEmptyArray() {
        // Given
        let service = makeService()

        // When
        let suggestions = service.getAllSuggestions()

        // Then
        XCTAssertFalse(suggestions.isEmpty)
    }

    func testGetAllSuggestions_ReturnsExpectedNames() {
        // Given
        let service = makeService()
        let expectedNames = [
            "Asuna Yuuki",
            "Kirito",
            "Leafa",
            "Sinon",
            "Alice",
            "Eugeo",
            "Yui",
            "Klein"
        ]

        // When
        let suggestions = service.getAllSuggestions()

        // Then
        XCTAssertEqual(suggestions, expectedNames)
    }

    func testGetAllSuggestions_AllNamesAreNonEmpty() {
        // Given
        let service = makeService()

        // When
        let suggestions = service.getAllSuggestions()

        // Then
        for name in suggestions {
            XCTAssertFalse(name.isEmpty, "Each suggestion should be non-empty")
        }
    }

    func testGetAllSuggestions_ReturnsConsistentResults() {
        // Given
        let service = makeService()

        // When
        let suggestions1 = service.getAllSuggestions()
        let suggestions2 = service.getAllSuggestions()

        // Then
        XCTAssertEqual(suggestions1, suggestions2, "Suggestions should be consistent")
    }

    func testGetAllSuggestions_ContainsNoDuplicates() {
        // Given
        let service = makeService()

        // When
        let suggestions = service.getAllSuggestions()
        let uniqueSuggestions = Set(suggestions)

        // Then
        XCTAssertEqual(
            suggestions.count,
            uniqueSuggestions.count,
            "Suggestions should have no duplicates"
        )
    }

    // MARK: - Multiple Instance Tests

    func testMultipleInstances_ProduceSameResults() {
        // Given
        let service1 = makeService()
        let service2 = makeService()

        // When
        let suggestions1 = service1.getAllSuggestions()
        let suggestions2 = service2.getAllSuggestions()

        // Then
        XCTAssertEqual(suggestions1, suggestions2)
    }
}
