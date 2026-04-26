//
//  AppRouter.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import SwiftUI

@Observable
@MainActor
final class AppRouter {
    var navigationPath = NavigationPath()

    /// Currently presented modal (displayed as overlay on top of navigation stack)
    var presentedModal: ModalRoute?

    init() {}

    // MARK: - Modal Presentation

    /// Presents a modal overlay on top of the current navigation stack
    func presentModal(_ modal: ModalRoute) {
        presentedModal = modal
    }

    /// Dismisses the currently presented modal
    func dismissModal() {
        presentedModal = nil
    }

    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }

    /// Pops every screen above the session's GameDayScreen.
    /// Assumes `.gameSession` is always at the bottom of `navigationPath`
    /// (MainMenuScreen is the NavigationStack root, outside the path).
    func popToGameDay() {
        let removeCount = max(navigationPath.count - 1, 0)
        navigationPath.removeLast(removeCount)
    }

    /// Navigates to a new route while removing specified number of previous routes from the stack
    /// - Parameters:
    ///   - route: The destination route
    ///   - count: Number of routes to remove before pushing the new one (default: 0)
    func navigate(to route: AppRoute, removingPrevious count: Int = 0) {
        let removeCount = min(count, navigationPath.count)
        navigationPath.removeLast(removeCount)
        navigationPath.append(route)
    }
}
