//
//  BattleFightRouteViewWiringTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import XCTest

/// T12 (view-viewmodel-boundary-fix, AC-04 / AC-07): `BattleFightRouteView`'s
/// `onBattleConcluded` closure must no longer call
/// `session.bankDungeonRewardsOnDeath()` directly, nor branch on the hero's
/// alive/dead state for banking purposes — that logic now lives exclusively
/// inside `BattleFightViewModel.finishBattle()` (landed by T5, already
/// unit-tested by `BattleFightViewModel_DeathRewardBankingTests` against a
/// real `GameSession`). `BattleFightScreen` already calls
/// `viewModel.finishBattle()` on `.onChange(of: viewModel.battleEnded)`
/// *before* invoking this closure, so a lingering direct call here would be a
/// harmless-but-duplicate bypass of the View/ViewModel boundary.
///
/// This is a source-content check (matching the `GameDayScreenWiringTests`/
/// `LoggerRoutingTests` convention in this project) rather than a
/// behavioural test — the DoD is literally "BattleFightRouteView.swift
/// contains no direct GameSession mutation for banking purposes", which is a
/// property of the source text (there is no SwiftUI view-hosting test
/// harness in this repo to drive the actual closure invocation).
final class BattleFightRouteViewWiringTests: XCTestCase {

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

    private func battleFightRouteViewSource() throws -> String {
        let url = elfIOSSourcesRoot
            .appendingPathComponent("Navigation/RouteViews/BattleFightRouteView.swift")
        return try String(contentsOf: url, encoding: .utf8)
    }

    /// DoD: "no longer calls session.bankDungeonRewardsOnDeath() directly" —
    /// that mutation now lives exclusively inside
    /// `BattleFightViewModel.finishBattle()` (T5).
    func test_noDirectSessionBankDungeonRewardsOnDeathCallRemainsInView() throws {
        let source = try battleFightRouteViewSource()
        XCTAssertFalse(
            source.contains("session.bankDungeonRewardsOnDeath("),
            "BattleFightRouteView must not call session.bankDungeonRewardsOnDeath() directly " +
                "— that duplicates the banking now owned by viewModel.finishBattle() (T5)"
        )
    }

    /// DoD: "or performs its own hero-alive/death check for banking
    /// purposes" — the `dungeon.heroIsDowned` branch existed solely to gate
    /// the now-removed direct banking call.
    func test_noHeroIsDownedCheckForBankingRemainsInView() throws {
        let source = try battleFightRouteViewSource()
        XCTAssertFalse(
            source.contains("heroIsDowned"),
            "BattleFightRouteView must not branch on hero-alive/death state for banking " +
                "purposes — that decision now lives exclusively inside viewModel.finishBattle() (T5)"
        )
    }
}
