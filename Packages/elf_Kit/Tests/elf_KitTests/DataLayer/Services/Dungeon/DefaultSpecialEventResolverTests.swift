//
//  DefaultSpecialEventResolverTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import XCTest
@testable import elf_Kit

/// Tests the pure event policy: `SpecialEvent` → `DungeonEventOutcome`.
final class DefaultSpecialEventResolverTests: XCTestCase {

    private let resolver = DefaultSpecialEventResolver()

    func testHealingSpring_FullyRestoresAndClearsRoom() {
        let outcome = resolver.resolve(.healingSpring)

        XCTAssertEqual(outcome.restore, .full)
        XCTAssertTrue(outcome.clearsRoom)
    }
}
