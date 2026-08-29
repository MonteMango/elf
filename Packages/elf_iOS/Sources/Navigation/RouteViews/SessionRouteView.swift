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
///
/// When `expectedGameId` is provided (only `.gameSession` does), the resolved
/// session's `GameID` must match it — a stale route pointing at a game that's
/// no longer active (e.g. after ending/reloading a game) silently pops back
/// to the previous screen instead of rendering with the wrong session.
internal struct SessionRouteView<Content: View>: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(AppRouter.self) private var router
    internal var expectedGameId: GameID?
    /// Called when `gameSession`/`dayStateViewModel` are already released
    /// instead of rendering empty — mirrors the stale-`expectedGameId`
    /// fallback below. Defaults to popping the navigation stack; modal
    /// presentations (e.g. `.battleResult`) pass `dismissModal()` instead.
    internal var onMissingSession: (AppRouter) -> Void = { $0.pop() }
    @ViewBuilder internal let content: (GameSession) -> Content

    internal init(
        expectedGameId: GameID? = nil,
        onMissingSession: @escaping (AppRouter) -> Void = { $0.pop() },
        @ViewBuilder content: @escaping (GameSession) -> Content
    ) {
        self.expectedGameId = expectedGameId
        self.onMissingSession = onMissingSession
        self.content = content
    }

    internal var body: some View {
        if let session = coordinator.gameSession,
           let dayStateVM = coordinator.dayStateViewModel {
            if sessionMatchesExpectedGameId(sessionGameId: session.state.gameId, expectedGameId: expectedGameId) {
                content(session)
                    .environment(dayStateVM)
            } else {
                Color.clear
                    .task { router.pop() }
            }
        } else {
            Color.clear
                .task { onMissingSession(router) }
        }
    }
}

/// Pure decision behind `SessionRouteView`'s gating: a `nil` `expectedGameId`
/// (e.g. `.calendar`) always matches; otherwise the session's `GameID` must
/// equal it, or the route is stale and should pop back instead of rendering.
internal func sessionMatchesExpectedGameId(sessionGameId: GameID, expectedGameId: GameID?) -> Bool {
    expectedGameId == nil || sessionGameId == expectedGameId
}
