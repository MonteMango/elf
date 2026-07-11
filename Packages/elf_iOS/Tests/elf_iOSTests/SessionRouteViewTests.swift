//
//  SessionRouteViewTests.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

@testable import elf_iOS
import elf_Kit
import XCTest

/// Tests for `SessionRouteView`'s expected-GameID match/mismatch decision
/// (T25, AC-05). No SwiftUI view-hosting harness exists in this test target,
/// so the pure decision extracted from `SessionRouteView.body` is what's
/// tested directly rather than the View itself.
@MainActor
final class SessionRouteViewTests: XCTestCase {

    func test_matchingGameId_matches() {
        let gameId = GameID()

        XCTAssertTrue(
            sessionMatchesExpectedGameId(sessionGameId: gameId, expectedGameId: gameId),
            "a session whose GameID matches the route's expected GameID must resolve/render"
        )
    }

    func test_mismatchedGameId_doesNotMatch() {
        let sessionGameId = GameID()
        let expectedGameId = GameID()

        XCTAssertFalse(
            sessionMatchesExpectedGameId(sessionGameId: sessionGameId, expectedGameId: expectedGameId),
            "a stale/non-matching GameID must not match, triggering AC-05's silent pop-back"
        )
    }

    func test_nilExpectedGameId_alwaysMatches() {
        let gameId = GameID()

        XCTAssertTrue(
            sessionMatchesExpectedGameId(sessionGameId: gameId, expectedGameId: nil),
            ".calendar (no expected GameID) always resolves the current session directly, with no gating"
        )
    }
}
