//
//  AppRouteTests.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

@testable import elf_iOS
import elf_Kit
import XCTest

/// Tests for `AppRoute.gameSession`'s equality/hashing (T18, AC-05/AC-07).
///
/// `.gameSession` must carry a `GameID` payload (not a full `Game`), and its
/// hand-written `==`/`hash(into:)` case must be gone — the synthesized
/// `Hashable` on `GameID` should reproduce the prior `Game.id`-based
/// comparison exactly: routes with the same `GameID` are equal/de-dup,
/// routes with different `GameID`s are not, and `playTime` never factors in.
@MainActor
final class AppRouteTests: XCTestCase {

    func test_gameSession_sameGameID_differentPlayTime_isEqualAndDeDupes() {
        let gameId = GameID()

        let route1 = AppRoute.gameSession(gameId, playTime: 10)
        let route2 = AppRoute.gameSession(gameId, playTime: 99)

        XCTAssertEqual(route1, route2, "same GameID must compare equal regardless of playTime")
        XCTAssertEqual(route1.hashValue, route2.hashValue, "same GameID must hash identically")
    }

    func test_gameSession_differentGameID_isNotEqual() {
        let route1 = AppRoute.gameSession(GameID(), playTime: 0)
        let route2 = AppRoute.gameSession(GameID(), playTime: 0)

        XCTAssertNotEqual(route1, route2, "different GameIDs must not compare equal")
    }

    /// `.calendar` (T19, AC-05/AC-07): converted to a zero-payload case with no
    /// hand-written `==`/`hash(into:)` — a payload-less case is always equal to
    /// itself, matching the prior "any two calendar pushes de-dup" behaviour.
    func test_calendar_isZeroPayload_andAlwaysEqualToItself() {
        let route1 = AppRoute.calendar
        let route2 = AppRoute.calendar

        XCTAssertEqual(route1, route2, "zero-payload .calendar must always compare equal to itself")
        XCTAssertEqual(route1.hashValue, route2.hashValue, ".calendar must hash identically")
    }
}
