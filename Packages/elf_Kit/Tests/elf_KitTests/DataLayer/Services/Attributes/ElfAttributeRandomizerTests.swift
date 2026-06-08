//
//  ElfAttributeRandomizerTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.07.25.
//

import Dependencies
import XCTest
@testable import elf_Kit

final class ElfAttributeRandomizerTests: XCTestCase {

    /// `ElfAttributeRandomizer.init` captures `\.withRandomNumberGenerator`;
    /// seed it so the distribution tests are deterministic.
    override func invokeTest() {
        withDependencies {
            $0.withRandomNumberGenerator = WithRandomNumberGenerator(
                SeededRandomNumberGenerator(seed: 0xE1F)
            )
        } operation: {
            super.invokeTest()
        }
    }

    func testReturnedAttributesAreValid() {
        let randomizer = ElfAttributeRandomizer()
        let allowed = Set(RandomAttributeKind.allCases)
        for _ in 0..<100 {
            let attr = randomizer.nextAttribute()
            XCTAssertTrue(allowed.contains(attr), "Unexpected attribute: \(attr)")
        }
    }

    func testRandomDistributionRoughlyMatchesWeights() {
        let randomizer = ElfAttributeRandomizer()
        var counts: [RandomAttributeKind: Int] = [:]

        let iterations = 10_000
        for _ in 0..<iterations {
            let attr = randomizer.nextAttribute()
            counts[attr, default: 0] += 1
        }

        // Uniform — each of the 5 kinds should land at ~20%.
        for kind in RandomAttributeKind.allCases {
            let actualRatio = Double(counts[kind, default: 0]) / Double(iterations)
            XCTAssertEqual(actualRatio, 0.2, accuracy: 0.03,
                           "\(kind): expected ~0.2, got \(actualRatio)")
        }
    }

    func testReturnsDifferentValuesOverTime() {
        let randomizer = ElfAttributeRandomizer()
        var seen = Set<RandomAttributeKind>()
        for _ in 0..<100 {
            seen.insert(randomizer.nextAttribute())
        }
        XCTAssertGreaterThan(seen.count, 1, "Randomizer returned only one unique value over 100 iterations")
    }
}
