//
//  NavigationContainer.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

// MARK: - Navigation Container
public struct NavigationContainer<Content: View>: View {
    @Bindable private var navigationManager: AppNavigationManager
    private let dependencyContainer: NewElfAppDependencyContainer
    private let rootView: Content

    @State private var lastPresentedModalRoute: AppRoute? = nil

    public init(
        navigationManager: AppNavigationManager,
        dependencyContainer: NewElfAppDependencyContainer,
        @ViewBuilder rootView: () -> Content
    ) {
        self.navigationManager = navigationManager
        self.dependencyContainer = dependencyContainer
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
                currentRoute.view(
                    container: dependencyContainer,
                    navigationManager: navigationManager
                )
                .transition(.opacity)
                .id(currentRoute)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: navigationManager.stack.count)
        .customModal(
            isPresented: Binding(
                get: { navigationManager.presentedModalRoute != nil },
                set: { if !$0 { navigationManager.dismissModal() } }
            )
        ) {
            // Use current route if available, otherwise use last presented route for animation
            let modalRoute = navigationManager.presentedModalRoute ?? lastPresentedModalRoute
            if let route = modalRoute {
                route.view(
                    container: dependencyContainer,
                    navigationManager: navigationManager
                )
            }
        }
        .onChange(of: navigationManager.presentedModalRoute) { oldValue, newValue in
            // Update lastPresentedModalRoute when new modal appears
            if let newRoute = newValue {
                lastPresentedModalRoute = newRoute
            }
            // Don't clear lastPresentedModalRoute when dismissed - let animation complete
        }
    }
}
