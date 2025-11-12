//
//  AppNavigationManager.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import SwiftUI

// MARK: - Navigation Manager
@Observable
public final class AppNavigationManager {

    public var stack: [AppRoute] = []

    public static let shared = AppNavigationManager()
    private init() {}

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
