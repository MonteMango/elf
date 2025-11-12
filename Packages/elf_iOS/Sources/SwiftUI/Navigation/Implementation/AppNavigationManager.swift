//
//  AppNavigationManager.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

// MARK: - Navigation Manager
@Observable
public final class AppNavigationManager {

    public var stack: [AppRoute] = []

    public init() {}

    public func push(_ route: AppRoute) {
        stack.append(route)
    }

    public func pop() {
        guard !stack.isEmpty else { return }
        stack.removeLast()
    }

    public func popToRoot() {
        stack.removeAll()
    }

    public func popTo(index: Int) {
        guard index >= 0 && index < stack.count else { return }
        stack = Array(stack.prefix(index + 1))
    }

    public func replace(with route: AppRoute) {
        stack = [route]
    }

    public func replaceStack(with routes: [AppRoute]) {
        stack = routes
    }
}

// MARK: - NavigationManaging Conformance
extension AppNavigationManager: NavigationManaging {

    public func push(_ route: any Route) {
        guard let appRoute = route as? AppRoute else {
            assertionFailure("Route must be of type AppRoute")
            return
        }
        push(appRoute)
    }

    public func replace(with route: any Route) {
        guard let appRoute = route as? AppRoute else {
            assertionFailure("Route must be of type AppRoute")
            return
        }
        replace(with: appRoute)
    }

    public func replaceStack(with routes: [any Route]) {
        let appRoutes = routes.compactMap { $0 as? AppRoute }
        guard appRoutes.count == routes.count else {
            assertionFailure("All routes must be of type AppRoute")
            return
        }
        replaceStack(with: appRoutes)
    }
}
