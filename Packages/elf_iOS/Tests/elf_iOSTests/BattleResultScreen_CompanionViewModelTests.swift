//
//  BattleResultScreen_CompanionViewModelTests.swift
//  elf_iOSTests
//
//  Created by Vitalii Lytvynov
//

@testable import elf_iOS
import elf_Kit
import XCTest

/// T11 / AC-03, AC-04, AC-07: `BattleResultScreen` must build its session-aware
/// `BattleResultCompletionViewModel` (T4) via the `GameSession` factory at init
/// time -- the same pattern `GameDayScreen` already uses for its second `@State`
/// view model (`session.makeInventoryViewModel()`, constructed inside
/// `init(session:)`) -- so the hero-death continuation path goes through the
/// companion VM's `finishRun()` instead of the View reaching into
/// `coordinator.gameSession?.finishDungeonRun()` + `.saveInBackground()`
/// directly.
///
/// No SwiftUI view-hosting harness exists in this test target (see
/// `SessionRouteViewTests`), so this proves the screen's *construction
/// surface* takes a `GameSession` and builds without crashing. The business
/// behaviour behind `finishRun()` itself (AC-03: no-op without an active run,
/// AC-04: no double-completion, AC-07: unit-testable without rendering a
/// View) is already proven directly against the VM in
/// `BattleResultCompletionViewModel_FinishRunTests` (elf_KitTests).
@MainActor
final class BattleResultScreen_CompanionViewModelTests: XCTestCase {

    func test_initAcceptsGameSession_toBuildCompanionViewModelViaFactory() {
        let session = PreviewGame.createMockSession()
        let result = ManualBattleResult(
            outcome: .defeat,
            experienceGained: 0,
            drops: [],
            previousLevel: 1,
            previousExp: 50,
            previousExpToNext: 100,
            newLevel: 1,
            newExp: 50,
            newExpToNext: 100
        )

        // Must compile once `BattleResultScreen` takes `session:` and builds
        // its companion VM via `session.makeBattleResultCompletionViewModel()`
        // internally, instead of only accepting `result:` and resolving
        // `GameSession` lazily through `@Environment(AppCoordinator.self)`
        // for direct mutation inside the View body.
        _ = BattleResultScreen(result: result, session: session)
    }
}
