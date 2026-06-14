//
//  SessionRouteView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

/// Wrapper used by `AppRoute.view()` to pass the active `GameSession`
/// into session-bound screens that declare `init(session:)`.
///
/// `AppRoute.view()` is a non-View context (no `@Environment`), so reading
/// the session is deferred to this small adapter view.
struct SessionRouteView<Content: View>: View {
    @Environment(AppCoordinator.self) private var coordinator
    @ViewBuilder let content: (GameSession) -> Content

    var body: some View {
        if let session = coordinator.gameSession,
           let dayStateVM = coordinator.dayStateViewModel {
            content(session)
                .environment(dayStateVM)
        }
    }
}

/// Specialized adapter for `BattleFightScreen`, which accepts an **optional** session
/// (the dev BattleSetup flow reaches it without an active game session).
struct BattleFightRouteView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let battle: Battle

    var body: some View {
        BattleFightScreen(
            battle: battle,
            session: coordinator.gameSession,
            // When a dungeon run is active, fold the finished battle's final
            // squad state back into it. No-op for hunt / dev battles (no run).
            onConclude: { finalLeftTeam, outcome in
                coordinator.gameSession?.dungeonSession?
                    .applyBattleOutcome(finalLeftTeam: finalLeftTeam, outcome: outcome)
            }
        )
    }
}
