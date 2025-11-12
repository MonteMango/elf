//
//  NavigationManaging.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Foundation

// MARK: - Route Protocol

/// Base protocol for all navigation routes
public protocol Route: Hashable {}

// MARK: - Navigation Manager Protocol

/// Protocol for managing navigation in the application
public protocol NavigationManaging {

    /// Pushes a new route onto the navigation stack
    /// - Parameter route: The route to push
    func push(_ route: any Route)

    /// Pops the top route from the navigation stack
    func pop()

    /// Pops all routes from the navigation stack, returning to the root
    func popToRoot()

    /// Pops routes until the specified index
    /// - Parameter index: The index to pop to
    func popTo(index: Int)

    /// Replaces the entire stack with a single route
    /// - Parameter route: The route to replace with
    func replace(with route: any Route)

    /// Replaces the entire navigation stack with new routes
    /// - Parameter routes: The routes to replace the stack with
    func replaceStack(with routes: [any Route])
}
