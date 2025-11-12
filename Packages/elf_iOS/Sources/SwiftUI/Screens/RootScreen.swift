//
//  RootScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

public struct RootScreen: View {

    @State private var navigationManager = AppNavigationManager()
    @State private var dependencyContainer = NewElfAppDependencyContainer()

    public init() {}

    public var body: some View {
        NavigationContainer(
            navigationManager: navigationManager,
            dependencyContainer: dependencyContainer
        ) {
            MainMenuScreen()
        }
        .environment(\.navigationManager, navigationManager)
    }
}

#Preview {
    RootScreen()
}
