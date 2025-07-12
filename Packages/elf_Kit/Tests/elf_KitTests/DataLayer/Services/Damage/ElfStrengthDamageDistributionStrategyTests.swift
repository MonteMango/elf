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

    func testDistributionForStrength1() {
        let result = strategy.distribution(for: 1)
        XCTAssertEqual(result.values, [0, 1])
        XCTAssertEqual(result.weights, [2, 1])
    }
    
    func testDistributionForStrength2() {
        let result = strategy.distribution(for: 2)
        XCTAssertEqual(result.values, [0, 1])
        XCTAssertEqual(result.weights, [2, 2])
    }
    
    func testDistributionForStrength3() {
        let result = strategy.distribution(for: 3)
        XCTAssertEqual(result.values, [0, 1, 2])
        XCTAssertEqual(result.weights, [2, 2, 1])
    }
    
    func testDistributionForStrength4() {
        let result = strategy.distribution(for: 4)
        XCTAssertEqual(result.values, [0, 1, 2])
        XCTAssertEqual(result.weights, [2, 2, 2])
    }
    
    func testDistributionForStrength5() {
        let result = strategy.distribution(for: 5)
        XCTAssertEqual(result.values, [0, 1, 2, 3])
        XCTAssertEqual(result.weights, [2, 2, 2, 1])
    }
    
    func testDistributionForStrength6() {
        let result = strategy.distribution(for: 6)
        XCTAssertEqual(result.values, [0, 1, 2, 3])
        XCTAssertEqual(result.weights, [2, 2, 2, 2])
    }
    
    func testDistributionForStrength7() {
        let result = strategy.distribution(for: 7)
        XCTAssertEqual(result.values, [0, 1, 2, 3, 4])
        XCTAssertEqual(result.weights, [1, 2, 2, 2, 1])
    }
    
    func testDistributionForStrength8() {
        let result = strategy.distribution(for: 8)
        XCTAssertEqual(result.values, [1, 2, 3, 4])
        XCTAssertEqual(result.weights, [2, 2, 2, 2])
    }
    
    func testDistributionForStrength9() {
        let result = strategy.distribution(for: 9)
        XCTAssertEqual(result.values, [1, 2, 3, 4, 5])
        XCTAssertEqual(result.weights, [1, 2, 2, 2, 1])
    }
    
    func testDistributionForStrength10() {
        let result = strategy.distribution(for: 10)
        XCTAssertEqual(result.values, [2, 3, 4, 5])
        XCTAssertEqual(result.weights, [2, 2, 2, 2])
    }
    
    func testDistributionForStrength11() {
        let result = strategy.distribution(for: 11)
        XCTAssertEqual(result.values, [2, 3, 4, 5, 6])
        XCTAssertEqual(result.weights, [1, 2, 2, 2, 1])
    }
    
    func testDistributionForStrength12() {
        let result = strategy.distribution(for: 12)
        XCTAssertEqual(result.values, [3, 4, 5, 6])
        XCTAssertEqual(result.weights, [2, 2, 2, 2])
    }
    
    func testDistributionForStrength13() {
        let result = strategy.distribution(for: 13)
        XCTAssertEqual(result.values, [4, 5, 6, 7])
        XCTAssertEqual(result.weights, [2, 2, 2, 1])
    }
    
    func testDistributionForStrength14() {
        let result = strategy.distribution(for: 14)
        XCTAssertEqual(result.values, [5, 6, 7])
        XCTAssertEqual(result.weights, [2, 2, 2])
    }
    
    func testDistributionForStrength15() {
        let result = strategy.distribution(for: 15)
        XCTAssertEqual(result.values, [5, 6, 7, 8])
        XCTAssertEqual(result.weights, [1, 2, 2, 1])
    }
    
    func testDistributionForStrength16() {
        let result = strategy.distribution(for: 16)
        XCTAssertEqual(result.values, [6, 7, 8])
        XCTAssertEqual(result.weights, [2, 2, 2])
    }
    
    func testDistributionForStrength17() {
        let result = strategy.distribution(for: 17)
        XCTAssertEqual(result.values, [6, 7, 8, 9])
        XCTAssertEqual(result.weights, [1, 2, 2, 1])
    }
    
    func testDistributionForStrength18() {
        let result = strategy.distribution(for: 18)
        XCTAssertEqual(result.values, [7, 8, 9])
        XCTAssertEqual(result.weights, [2, 2, 2])
    }
    
    func testDistributionForStrength19() {
        let result = strategy.distribution(for: 19)
        XCTAssertEqual(result.values, [7, 8, 9, 10])
        XCTAssertEqual(result.weights, [1, 2, 2, 1])
    }
    
    func testDistributionForStrength20() {
        let result = strategy.distribution(for: 20)
        XCTAssertEqual(result.values, [8, 9, 10])
        XCTAssertEqual(result.weights, [2, 2, 2])
    }
    
    func testDistributionForStrength21() {
        let result = strategy.distribution(for: 21)
        XCTAssertEqual(result.values, [8, 9, 10, 11])
        XCTAssertEqual(result.weights, [1, 2, 2, 1])
    }
    
    func testDistributionForStrength22() {
        let result = strategy.distribution(for: 22)
        XCTAssertEqual(result.values, [9, 10, 11])
        XCTAssertEqual(result.weights, [2, 2, 2])
    }
    
    func testDistributionForStrength23() {
        let result = strategy.distribution(for: 23)
        XCTAssertEqual(result.values, [9, 10, 11, 12])
        XCTAssertEqual(result.weights, [1, 2, 2, 1])
    }
    
    func testDistributionForStrength24() {
        let result = strategy.distribution(for: 24)
        XCTAssertEqual(result.values, [10, 11, 12])
        XCTAssertEqual(result.weights, [2, 2, 2])
    }
    
    func testDistributionForStrength25() {
        let result = strategy.distribution(for: 25)
        XCTAssertEqual(result.values, [11, 12, 13])
        XCTAssertEqual(result.weights, [2, 2, 1])
    }
    
    func testDistributionForStrength26() {
        let result = strategy.distribution(for: 26)
        XCTAssertEqual(result.values, [12, 13])
        XCTAssertEqual(result.weights, [2, 2])
    }
    
    func testDistributionForStrength27() {
        let result = strategy.distribution(for: 27)
        XCTAssertEqual(result.values, [12, 13, 14])
        XCTAssertEqual(result.weights, [1, 2, 1])
    }
    
    func testDistributionForStrength28() {
        let result = strategy.distribution(for: 28)
        XCTAssertEqual(result.values, [13, 14])
        XCTAssertEqual(result.weights, [2, 2])
    }
    
    func testDistributionForStrength29() {
        let result = strategy.distribution(for: 29)
        XCTAssertEqual(result.values, [13, 14, 15])
        XCTAssertEqual(result.weights, [1, 2, 1])
    }
    
    func testDistributionForStrength30() {
        let result = strategy.distribution(for: 30)
        XCTAssertEqual(result.values, [14, 15])
        XCTAssertEqual(result.weights, [2, 2])
    }
    
    func testDistributionForStrength35() {
        let result = strategy.distribution(for: 35)
        XCTAssertEqual(result.values, [16, 17, 18])
        XCTAssertEqual(result.weights, [1, 2, 1])
    }
    
    func testDistributionForStrength40() {
        let result = strategy.distribution(for: 40)
        XCTAssertEqual(result.values, [19, 20])
        XCTAssertEqual(result.weights, [2, 2])
    }
    
    func testDistributionForStrength45() {
        let result = strategy.distribution(for: 45)
        XCTAssertEqual(result.values, [21, 22, 23])
        XCTAssertEqual(result.weights, [1, 2, 1])
    }
    
    func testDistributionForStrength50() {
        let result = strategy.distribution(for: 50)
        XCTAssertEqual(result.values, [24, 25])
        XCTAssertEqual(result.weights, [2, 2])
    }
    
    func testDistributionForStrength75() {
        let result = strategy.distribution(for: 75)
        XCTAssertEqual(result.values, [36, 37, 38])
        XCTAssertEqual(result.weights, [1, 2, 1])
    }
    
    func testDistributionForStrength80() {
        let result = strategy.distribution(for: 80)
        XCTAssertEqual(result.values, [39, 40])
        XCTAssertEqual(result.weights, [2, 2])
    }
    
    func testDistributionForStrength100() {
        let result = strategy.distribution(for: 100)
        XCTAssertEqual(result.values, [49, 50])
        XCTAssertEqual(result.weights, [2, 2])
    }
}
