//
//  NavigationContainer.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import SwiftUI

// MARK: - Navigation Container
public struct NavigationContainer<Content: View>: View {
    @Environment(\.navigationManager) private var navigationManager
    private let rootView: Content

    public init(@ViewBuilder rootView: () -> Content) {
        self.rootView = rootView()
    }
    
    public var body: some View {
        ZStack {
            if navigationManager.stack.isEmpty {
                // Show root view when stack is empty
                rootView
                    .transition(.opacity)
                    .id("root")
            } else if let currentRoute = navigationManager.stack.last {
                // Show only the last (current) screen from stack
                currentRoute.view()
                    .transition(.opacity)
                    .id(currentRoute)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: navigationManager.stack.count)
    }
}

// MARK: - Extension
public extension View {
    func withNavigation() -> some View {
        NavigationContainer {
            self
        }
    }
}
