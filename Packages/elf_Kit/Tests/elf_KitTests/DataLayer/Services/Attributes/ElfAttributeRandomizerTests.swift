//
//  ElfAttributeRandomizerTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.07.25.
//

import XCTest
@testable import elf_Kit

final class ElfAttributeRandomizerTests: XCTestCase {
    func testReturnedAttributesAreValid() {
        let randomizer = ElfAttributeRandomizer()
        let allowedAttributes: Set<String> = ["hitPoints", "manaPoints", "agility", "strength", "power", "instinct"]

        for _ in 0..<100 {
            let attr = randomizer.nextAttribute()
            XCTAssertTrue(allowedAttributes.contains(attr), "Unexpected attribute: \(attr)")
        }
    }

    func testRandomDistributionRoughlyMatchesWeights() {
        let randomizer = ElfAttributeRandomizer()
        var counts: [String: Int] = [:]

        let iterations = 10_000
        for _ in 0..<iterations {
            let attr = randomizer.nextAttribute()
            counts[attr, default: 0] += 1
        }

        // Проверим примерный процент (с учетом допуска)
        let expectedDistribution: [String: Double] = [
            "hitPoints": 0.10,
            "manaPoints": 0.10,
            "agility": 0.20,
            "strength": 0.20,
            "power": 0.20,
            "instinct": 0.20
        ]

        for (attr, expectedRatio) in expectedDistribution {
            let actualRatio = Double(counts[attr, default: 0]) / Double(iterations)
            XCTAssertTrue(abs(actualRatio - expectedRatio) < 0.03, "\(attr): expected ~\(expectedRatio), got \(actualRatio)")
        }
    }

    func testReturnsDifferentValuesOverTime() {
        let randomizer = ElfAttributeRandomizer()
        var seenAttributes = Set<String>()

        for _ in 0..<100 {
            seenAttributes.insert(randomizer.nextAttribute())
        }

        XCTAssertTrue(seenAttributes.count > 1, "Randomizer returned only one unique value over 100 iterations")
    }
}
