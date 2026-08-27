//
//  GameDayScreenWiringTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import XCTest

/// T9 (view-viewmodel-boundary-fix, AC-01 / AC-02 / AC-02b / AC-07): the
/// dungeon action button in `GameDayScreen` must call
/// `viewModel.startDungeonRun()` (T2, already unit-tested against
/// `GameDayViewModel` directly for AC-01/AC-02/AC-02b/AC-07) instead of
/// reaching around the ViewModel to mutate `session` directly.
///
/// This is a source-content check (matching the `LoggerRoutingTests`
/// convention in this project) rather than a behavioural test — the DoD is
/// literally "GameDayScreen.swift contains no direct GameSession/
/// DungeonSession mutation", which is a property of the source text (there
/// is no SwiftUI view-tap testing harness in this repo to drive the actual
/// button), and "no duplicate AP debit remains", which this rules out by
/// removing the second (View-level) call path entirely — the single
/// remaining AP debit is the one already covered by
/// `GameDayViewModel_StartDungeonRunTests` (T2).
final class GameDayScreenWiringTests: XCTestCase {

    /// `elf_iOS/Sources/...` root, resolved relative to this test file so it
    /// works regardless of the machine's checkout path.
    private var elfIOSSourcesRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Architecture/
            .deletingLastPathComponent() // elf_KitTests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // elf_Kit/
            .deletingLastPathComponent() // Packages/
            .appendingPathComponent("elf_iOS")
            .appendingPathComponent("Sources")
    }

    private func gameDayScreenSource() throws -> String {
        let url = elfIOSSourcesRoot
            .appendingPathComponent("Screens/GameDayScreen/GameDayScreen.swift")
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// `elf_Kit/Sources/...` root, resolved relative to this test file.
    private var elfKitSourcesRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Architecture/
            .deletingLastPathComponent() // elf_KitTests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // (now at .../Packages/elf_Kit/)
            .appendingPathComponent("Sources")
    }

    private func gameDayViewModelSource() throws -> String {
        let url = elfKitSourcesRoot
            .appendingPathComponent("UILayer/GameDay/GameDayViewModel.swift")
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// AC-01/AC-02/AC-02b: the dungeon action closure must delegate the
    /// start-run decision to `viewModel.startDungeonRun()` instead of
    /// duplicating it locally against `session` directly.
    func test_dungeonActionCallsViewModelStartDungeonRun() throws {
        let source = try gameDayScreenSource()
        XCTAssertTrue(
            source.contains("viewModel.startDungeonRun()"),
            "GameDayScreen's dungeon action must call viewModel.startDungeonRun() (added by T2)"
        )
    }

    /// DoD: "no duplicate AP debit remains" — the View must no longer call
    /// `session.startDungeonSession(...)` directly; that mutation now lives
    /// exclusively inside `GameDayViewModel.startDungeonRun()`.
    func test_noDirectSessionStartDungeonSessionCallRemainsInView() throws {
        let source = try gameDayScreenSource()
        XCTAssertFalse(
            source.contains("session.startDungeonSession("),
            "GameDayScreen must not mutate session.startDungeonSession(...) directly " +
                "— that duplicates the debit now owned by viewModel.startDungeonRun()"
        )
    }

    /// DoD: "GameDayScreen.swift contains no direct GameSession/
    /// DungeonSession mutation" — `prepareDungeonRun()` was the old
    /// AP-unaware picker superseded by `startDungeonRun()`; if it's still
    /// referenced from the dungeon action, the old dual-call path (pick +
    /// separately mutate session) is still present.
    func test_dungeonActionDoesNotStillCallPrepareDungeonRun() throws {
        let source = try gameDayScreenSource()
        XCTAssertFalse(
            source.contains("viewModel.prepareDungeonRun()"),
            "GameDayScreen's dungeon action must no longer call the superseded " +
                "prepareDungeonRun() — it must call startDungeonRun() instead"
        )
    }

    /// AC-02/AC-02b (review finding #3): navigation must be decided from
    /// `startDungeonRun()`'s own return value, not by re-reading
    /// `session.dungeonSession` — reading session state for navigation
    /// reproduces the View↔GameSession coupling this whole feature removes.
    func test_dungeonActionDoesNotReadSessionDungeonSessionForNavigation() throws {
        let source = try gameDayScreenSource()
        XCTAssertFalse(
            source.contains("session.dungeonSession"),
            "GameDayScreen must navigate on startDungeonRun()'s return value, " +
                "not by reading session.dungeonSession directly"
        )
    }

    /// Review finding (stage-2): `prepareDungeonRun()` was superseded by
    /// `startDungeonRun()` (T2) and, since T9 wired the View off it, had no
    /// remaining callers — an orphaned duplicate of the squad-picking logic.
    func test_gameDayViewModelNoLongerDeclaresPrepareDungeonRun() throws {
        let source = try gameDayViewModelSource()
        XCTAssertFalse(
            source.contains("func prepareDungeonRun("),
            "GameDayViewModel.prepareDungeonRun() is orphaned (no callers) and must be removed"
        )
    }
}
