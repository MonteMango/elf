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

    public init() {}

    public func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    public func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}
