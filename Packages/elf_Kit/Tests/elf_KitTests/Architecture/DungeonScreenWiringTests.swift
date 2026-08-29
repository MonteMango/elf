//
//  DungeonScreenWiringTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import XCTest

/// T10 (view-viewmodel-boundary-fix, AC-03 / AC-04 / AC-07): the "Finish"
/// room-action branch in `DungeonScreen.performRoomAction()` must call
/// `viewModel.finishRun()` (T3, already unit-tested against
/// `DungeonViewModel` directly for AC-03/AC-04/AC-07 in
/// `DungeonViewModel_FinishRunTests`) instead of reaching around the
/// ViewModel to call `gameSession.finishDungeonRun()` + `.saveInBackground()`
/// directly.
///
/// This is a source-content check (matching the `GameDayScreenWiringTests` /
/// `LoggerRoutingTests` convention in this project) rather than a
/// behavioural test — the DoD is literally "DungeonScreen.swift contains no
/// direct GameSession mutation", which is a property of the source text
/// (there is no SwiftUI view-tap testing harness in this repo to drive the
/// actual button), and the pop-before-finish ordering, which this also
/// checks textually since the finish logic itself (idempotent no-op,
/// no-active-run guard) is already covered by
/// `DungeonViewModel_FinishRunTests` (T3).
final class DungeonScreenWiringTests: XCTestCase {

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

    private func dungeonScreenSource() throws -> String {
        let url = elfIOSSourcesRoot
            .appendingPathComponent("Screens/DungeonScreen/DungeonScreen.swift")
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// AC-03/AC-04/AC-07: the `.finish` action-kind branch must delegate to
    /// `viewModel.finishRun()` instead of duplicating finish+save locally.
    func test_finishActionCallsViewModelFinishRun() throws {
        let source = try dungeonScreenSource()
        XCTAssertTrue(
            source.contains("viewModel.finishRun()"),
            "DungeonScreen's .finish action must call viewModel.finishRun() (added by T3)"
        )
    }

    /// DoD: "DungeonScreen.swift contains no direct GameSession mutation" —
    /// the View must no longer call `gameSession.finishDungeonRun()`
    /// directly; that mutation now lives exclusively inside
    /// `GameSession.completeDungeonRun()`, reached via
    /// `viewModel.finishRun()`.
    func test_noDirectGameSessionFinishDungeonRunCallRemainsInView() throws {
        let source = try dungeonScreenSource()
        XCTAssertFalse(
            source.contains("gameSession.finishDungeonRun()"),
            "DungeonScreen must not mutate gameSession.finishDungeonRun() directly " +
                "— that duplicates the finish logic now owned by viewModel.finishRun()"
        )
    }

    /// DoD: "DungeonScreen.swift contains no direct GameSession mutation" —
    /// the View must no longer call `gameSession.saveInBackground()`
    /// directly on the finish path; the save is now owned by
    /// `GameSession.completeDungeonRun()`.
    func test_noDirectGameSessionSaveInBackgroundCallRemainsInView() throws {
        let source = try dungeonScreenSource()
        XCTAssertFalse(
            source.contains("gameSession.saveInBackground()"),
            "DungeonScreen must not call gameSession.saveInBackground() directly " +
                "— that save is now owned by viewModel.finishRun() -> completeDungeonRun()"
        )
    }

    /// DoD: "router.popToGameDay() still runs before viewModel.finishRun(),
    /// with no await in between" — the pop-before-release ordering is
    /// load-bearing (sad §6 Flow 2) and must be preserved textually: the pop
    /// call must appear before the finish call inside the `.finish` case.
    func test_popToGameDayStillPrecedesFinishRunCall() throws {
        let source = try dungeonScreenSource()
        guard let popRange = source.range(of: "router.popToGameDay()"),
              let finishRange = source.range(of: "viewModel.finishRun()") else {
            XCTFail("expected both router.popToGameDay() and viewModel.finishRun() to be present in DungeonScreen")
            return
        }
        XCTAssertTrue(
            popRange.lowerBound < finishRange.lowerBound,
            "router.popToGameDay() must run before viewModel.finishRun() — " +
                "no await may sit between pop and session release (sad §6 Flow 2)"
        )
    }
}
