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
internal struct SessionRouteView<Content: View>: View {
    @Environment(AppCoordinator.self) private var coordinator
    @ViewBuilder internal let content: (GameSession) -> Content

    internal var body: some View {
        if let session = coordinator.gameSession,
           let dayStateVM = coordinator.dayStateViewModel {
            content(session)
                .environment(dayStateVM)
        }
    }
}
