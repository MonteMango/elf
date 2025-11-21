//
//  ElfStrengthDamageDistributionStrategyTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.07.25.
//

import XCTest
@testable import elf_Kit

final class ElfStrengthDamageDistributionStrategyTests: XCTestCase {

    private let strategy = ElfStrengthDamageDistributionStrategy()

    // MARK: - Predefined Distributions (1-52)

    func testDistributionForStrength1() {
        let result = strategy.distribution(for: 1)
        XCTAssertEqual(result.values, [0, 1])
        XCTAssertEqual(result.weights, [3, 1])
    }

    func testDistributionForStrength2() {
        let result = strategy.distribution(for: 2)
        XCTAssertEqual(result.values, [0, 1])
        XCTAssertEqual(result.weights, [3, 2])
    }

    func testDistributionForStrength3() {
        let result = strategy.distribution(for: 3)
        XCTAssertEqual(result.values, [0, 1])
        XCTAssertEqual(result.weights, [3, 3])
    }

    func testDistributionForStrength4() {
        let result = strategy.distribution(for: 4)
        XCTAssertEqual(result.values, [0, 1, 2])
        XCTAssertEqual(result.weights, [3, 3, 1])
    }

    func testDistributionForStrength5() {
        let result = strategy.distribution(for: 5)
        XCTAssertEqual(result.values, [0, 1, 2])
        XCTAssertEqual(result.weights, [3, 3, 2])
    }

    func testDistributionForStrength6() {
        let result = strategy.distribution(for: 6)
        XCTAssertEqual(result.values, [0, 1, 2])
        XCTAssertEqual(result.weights, [3, 3, 3])
    }

    func testDistributionForStrength7() {
        let result = strategy.distribution(for: 7)
        XCTAssertEqual(result.values, [0, 1, 2, 3])
        XCTAssertEqual(result.weights, [3, 3, 3, 1])
    }

    func testDistributionForStrength8() {
        let result = strategy.distribution(for: 8)
        XCTAssertEqual(result.values, [0, 1, 2, 3])
        XCTAssertEqual(result.weights, [3, 3, 3, 2])
    }

    func testDistributionForStrength9() {
        let result = strategy.distribution(for: 9)
        XCTAssertEqual(result.values, [0, 1, 2, 3])
        XCTAssertEqual(result.weights, [3, 3, 3, 3])
    }

    func testDistributionForStrength10() {
        let result = strategy.distribution(for: 10)
        XCTAssertEqual(result.values, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.weights, [3, 3, 3, 3, 1])
    }

    func testDistributionForStrength11() {
        let result = strategy.distribution(for: 11)
        XCTAssertEqual(result.values, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.weights, [3, 3, 3, 3, 2])
    }

    func testDistributionForStrength12() {
        let result = strategy.distribution(for: 12)
        XCTAssertEqual(result.values, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.weights, [3, 3, 3, 3, 3])
    }

    func testDistributionForStrength13() {
        let result = strategy.distribution(for: 13)
        XCTAssertEqual(result.values, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.weights, [2, 3, 3, 3, 3])
    }

    func testDistributionForStrength14() {
        let result = strategy.distribution(for: 14)
        XCTAssertEqual(result.values, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.weights, [1, 3, 3, 3, 3])
    }

    func testDistributionForStrength15() {
        let result = strategy.distribution(for: 15)
        XCTAssertEqual(result.values, [1, 2, 3, 4])
        XCTAssertEqual(result.weights, [3, 3, 3, 3])
    }

    func testDistributionForStrength16() {
        let result = strategy.distribution(for: 16)
        XCTAssertEqual(result.values, [1, 2, 3, 4])
        XCTAssertEqual(result.weights, [2, 3, 3, 3])
    }

    func testDistributionForStrength17() {
        let result = strategy.distribution(for: 17)
        XCTAssertEqual(result.values, [1, 2, 3, 4])
        XCTAssertEqual(result.weights, [1, 3, 3, 3])
    }

    func testDistributionForStrength18() {
        let result = strategy.distribution(for: 18)
        XCTAssertEqual(result.values, [2, 3, 4])
        XCTAssertEqual(result.weights, [3, 3, 3])
    }

    func testDistributionForStrength19() {
        let result = strategy.distribution(for: 19)
        XCTAssertEqual(result.values, [2, 3, 4, 5])
        XCTAssertEqual(result.weights, [3, 3, 3, 1])
    }

    func testDistributionForStrength20() {
        let result = strategy.distribution(for: 20)
        XCTAssertEqual(result.values, [2, 3, 4, 5])
        XCTAssertEqual(result.weights, [3, 3, 3, 2])
    }

    func testDistributionForStrength21() {
        let result = strategy.distribution(for: 21)
        XCTAssertEqual(result.values, [2, 3, 4, 5])
        XCTAssertEqual(result.weights, [3, 3, 3, 3])
    }

    func testDistributionForStrength22() {
        let result = strategy.distribution(for: 22)
        XCTAssertEqual(result.values, [2, 3, 4, 5])
        XCTAssertEqual(result.weights, [2, 3, 3, 3])
    }

    func testDistributionForStrength23() {
        let result = strategy.distribution(for: 23)
        XCTAssertEqual(result.values, [2, 3, 4, 5])
        XCTAssertEqual(result.weights, [1, 3, 3, 3])
    }

    func testDistributionForStrength24() {
        let result = strategy.distribution(for: 24)
        XCTAssertEqual(result.values, [3, 4, 5])
        XCTAssertEqual(result.weights, [3, 3, 3])
    }

    func testDistributionForStrength25() {
        let result = strategy.distribution(for: 25)
        XCTAssertEqual(result.values, [3, 4, 5, 6])
        XCTAssertEqual(result.weights, [3, 3, 3, 1])
    }

    func testDistributionForStrength26() {
        let result = strategy.distribution(for: 26)
        XCTAssertEqual(result.values, [3, 4, 5, 6])
        XCTAssertEqual(result.weights, [3, 3, 3, 2])
    }

    func testDistributionForStrength27() {
        let result = strategy.distribution(for: 27)
        XCTAssertEqual(result.values, [3, 4, 5, 6])
        XCTAssertEqual(result.weights, [3, 3, 3, 3])
    }

    func testDistributionForStrength28() {
        let result = strategy.distribution(for: 28)
        XCTAssertEqual(result.values, [3, 4, 5, 6])
        XCTAssertEqual(result.weights, [2, 3, 3, 3])
    }

    func testDistributionForStrength29() {
        let result = strategy.distribution(for: 29)
        XCTAssertEqual(result.values, [3, 4, 5, 6])
        XCTAssertEqual(result.weights, [1, 3, 3, 3])
    }

    func testDistributionForStrength30() {
        let result = strategy.distribution(for: 30)
        XCTAssertEqual(result.values, [4, 5, 6])
        XCTAssertEqual(result.weights, [3, 3, 3])
    }

    func testDistributionForStrength45() {
        let result = strategy.distribution(for: 45)
        XCTAssertEqual(result.values, [7, 8])
        XCTAssertEqual(result.weights, [3, 3])
    }

    func testDistributionForStrength48() {
        let result = strategy.distribution(for: 48)
        XCTAssertEqual(result.values, [8])
        XCTAssertEqual(result.weights, [1])
    }

    func testDistributionForStrength50() {
        let result = strategy.distribution(for: 50)
        XCTAssertEqual(result.values, [8, 9])
        XCTAssertEqual(result.weights, [3, 2])
    }

    func testDistributionForStrength52() {
        let result = strategy.distribution(for: 52)
        XCTAssertEqual(result.values, [9])
        XCTAssertEqual(result.weights, [1])
    }

    // MARK: - Extended Distributions (53+)

    func testDistributionForStrength53() {
        // like 45 but with baseValue 8
        let result = strategy.distribution(for: 53)
        XCTAssertEqual(result.values, [8, 9])
        XCTAssertEqual(result.weights, [3, 3])
    }

    func testDistributionForStrength56() {
        // like 48 but with baseValue 8
        let result = strategy.distribution(for: 56)
        XCTAssertEqual(result.values, [9])
        XCTAssertEqual(result.weights, [1])
    }

    func testDistributionForStrength60() {
        // like 52 but with baseValue 8
        let result = strategy.distribution(for: 60)
        XCTAssertEqual(result.values, [10])
        XCTAssertEqual(result.weights, [1])
    }

    func testDistributionForStrength61() {
        // like 45 but with baseValue 9
        let result = strategy.distribution(for: 61)
        XCTAssertEqual(result.values, [9, 10])
        XCTAssertEqual(result.weights, [3, 3])
    }

    func testDistributionForStrength75() {
        // 75 = 45 + 30 = 45 + 3*8 + 6
        // baseValue = 7 + 3 = 10, cyclePosition = 6
        let result = strategy.distribution(for: 75)
        XCTAssertEqual(result.values, [11, 12])
        XCTAssertEqual(result.weights, [3, 3])
    }

    func testDistributionForStrength80() {
        // 80 = 45 + 35 = 45 + 4*8 + 3
        // baseValue = 7 + 4 = 11, cyclePosition = 3
        let result = strategy.distribution(for: 80)
        XCTAssertEqual(result.values, [12])
        XCTAssertEqual(result.weights, [1])
    }

    func testDistributionForStrength100() {
        // 100 = 45 + 55 = 45 + 6*8 + 7
        // baseValue = 7 + 6 = 13, cyclePosition = 7
        let result = strategy.distribution(for: 100)
        XCTAssertEqual(result.values, [15])
        XCTAssertEqual(result.weights, [1])
    }
}
