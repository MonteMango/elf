//
//  AppRouter.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import elf_Kit
import SwiftUI

@Observable
@MainActor
internal final class AppRouter {
    /// The navigation stack, typed so the top can be inspected for idempotent
    /// pushes. Write access is closed off (`private(set)`): all mutation goes
    /// through `navigate(to:)` / `pushBattle(_:)` / `pop*()`, so no screen can
    /// bypass the dedup by poking the path directly. External reads (e.g.
    /// `navigationPath.count`) stay available.
    internal private(set) var navigationPath: [AppRoute] = []

    /// Currently presented modal (displayed as overlay on top of navigation stack)
    internal var presentedModal: ModalRoute?

    internal init() {}

    // MARK: - Navigation Stack Binding

    /// The sole writable entry point for `NavigationStack` — it must write the
    /// path back on system pop / swipe-back. The setter lives inside the class,
    /// so `private(set)` on `navigationPath` does not block it. Do NOT use this
    /// for programmatic navigation — call `navigate(to:)` / `pushBattle(_:)` /
    /// `pop()` instead, which keep the dedup invariants.
    internal var navigationStackBinding: Binding<[AppRoute]> {
        Binding(get: { self.navigationPath }, set: { self.navigationPath = $0 })
    }

    // MARK: - Modal Presentation

    /// Presents a modal overlay on top of the current navigation stack
    internal func presentModal(_ modal: ModalRoute) {
        presentedModal = modal
    }

    /// Dismisses the currently presented modal
    internal func dismissModal() {
        presentedModal = nil
    }

    internal func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    internal func popToRoot() {
        navigationPath.removeAll()
    }

    /// Pops every screen above the session's GameDayScreen.
    /// Assumes `.gameSession` is always at the bottom of `navigationPath`
    /// (MainMenuScreen is the NavigationStack root, outside the path).
    internal func popToGameDay() {
        navigationPath = Array(navigationPath.prefix(1))
    }

    /// Navigates to a new route while removing specified number of previous routes from the stack
    /// - Parameters:
    ///   - route: The destination route
    ///   - count: Number of routes to remove before pushing the new one (default: 0)
    ///
    /// Idempotent: a route equal to the current top (after the requested removal)
    /// is dropped, so a fast double-tap can't push the same screen twice.
    internal func navigate(to route: AppRoute, removingPrevious count: Int = 0) {
        let removeCount = min(count, navigationPath.count)
        navigationPath.removeLast(removeCount)
        guard navigationPath.last != route else { return }
        navigationPath.append(route)
    }

    /// Pushes a battle screen, never stacking one battle on top of another.
    /// `startHunt()`/`startRoomBattle()`/`startBattle()` mint a fresh `Battle`
    /// (new `id`) per call, so the routes are never equal — equality dedup would
    /// miss it. A double-tap during the push animation is therefore caught by a
    /// case-level guard instead. Pop frees it: once the top is no longer a
    /// `.battleFight`, the next battle pushes normally.
    internal func pushBattle(_ battle: Battle) {
        if case .battleFight = navigationPath.last { return }
        navigationPath.append(.battleFight(battle))
    }
}
