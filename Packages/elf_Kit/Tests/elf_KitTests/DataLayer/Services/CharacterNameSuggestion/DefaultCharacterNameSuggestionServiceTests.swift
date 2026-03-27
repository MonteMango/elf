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
final class DefaultCharacterNameSuggestionServiceTests: XCTestCase {

    // MARK: - Test Helpers

    private func makeService() -> DefaultCharacterNameSuggestionService {
        return DefaultCharacterNameSuggestionService()
    }

    // MARK: - Generate Random Name Tests

    func testGenerateRandomName_ReturnsNonEmptyString() async {
        // Given
        let service = makeService()

        // When
        let name = await service.generateRandomName()

        // Then
        XCTAssertFalse(name.isEmpty)
    }

    func testGenerateRandomName_ProducesVariety() async {
        // Given
        let service = makeService()
        var generatedNames: Set<String> = []

        // When: Generate many names
        for _ in 0..<100 {
            let name = await service.generateRandomName()
            generatedNames.insert(name)
        }

        // Then: Should have some variety
        XCTAssertGreaterThan(
            generatedNames.count,
            1,
            "Should generate different names over multiple calls"
        )
    }
}
