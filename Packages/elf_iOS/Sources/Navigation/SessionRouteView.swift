//
//  SessionRouteView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

/// Wrapper used by `AppRoute.view()` to pass the active `GameSessionModel`
/// into session-bound screens that declare `init(session:)`.
///
/// `AppRoute.view()` is a non-View context (no `@Environment`), so reading
/// the session is deferred to this small adapter view.
struct SessionRouteView<Content: View>: View {
    @Environment(AppCoordinator.self) private var coordinator
    @ViewBuilder let content: (GameSessionModel) -> Content

    var body: some View {
        if let session = coordinator.sessionModel {
            content(session)
        }
    }
}

/// Specialized adapter for `BattleFightScreen`, which accepts an **optional** session
/// (the dev BattleSetup flow reaches it without an active game session).
struct BattleFightRouteView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let battle: Battle

    var body: some View {
        BattleFightScreen(battle: battle, session: coordinator.sessionModel)
    }
}
