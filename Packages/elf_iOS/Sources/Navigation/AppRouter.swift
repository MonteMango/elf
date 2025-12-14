//
//  AppRouter.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import SwiftUI

@Observable
public final class AppRouter {
    public var navigationPath = NavigationPath()

    /// Currently presented modal (displayed as overlay on top of navigation stack)
    public var presentedModal: ModalRoute?

    public init() {}

    // MARK: - Modal Presentation

    /// Presents a modal overlay on top of the current navigation stack
    public func presentModal(_ modal: ModalRoute) {
        presentedModal = modal
    }

    /// Dismisses the currently presented modal
    public func dismissModal() {
        presentedModal = nil
    }

    public func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    public func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }

    /// Navigates to a new route while removing specified number of previous routes from the stack
    /// - Parameters:
    ///   - route: The destination route
    ///   - count: Number of routes to remove before pushing the new one (default: 0)
    public func navigate(to route: AppRoute, removingPrevious count: Int = 0) {
        let removeCount = min(count, navigationPath.count)
        navigationPath.removeLast(removeCount)
        navigationPath.append(route)
    }
}
