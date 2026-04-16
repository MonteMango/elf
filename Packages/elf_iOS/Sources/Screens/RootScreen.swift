//
//  RootScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

public struct RootScreen: View {

    @Environment(ElfAppContainer.self) private var appContainer
    @State private var router = AppRouter()
    @Namespace private var farmZoomNamespace
    @Namespace private var questZoomNamespace

    public init() {}

    public var body: some View {
        NavigationStack(path: $router.navigationPath) {
            MainMenuScreen()
                .navigationDestination(for: AppRoute.self) { route in
                    route.view()
                        .gameContainerEnvironment(appContainer.gameContainer)
                        .navigationBarBackButtonHidden(true)
                        .toolbar(.hidden, for: .navigationBar)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("")
                }
        }
        .allowsHitTesting(router.presentedModal == nil)
        .overlay {
            // Modal layer - displayed on top of navigation stack
            if let modal = router.presentedModal {
                modal.view()
                    .gameContainerEnvironment(appContainer.gameContainer)
            }
        }
        .environment(\.farmZoomNamespace, farmZoomNamespace)
        .environment(\.questZoomNamespace, questZoomNamespace)
        .environment(router)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - GameContainer Environment Injection

private extension View {

    /// Injects `ElfGameContainer` into the environment so screens can access
    /// ViewModel factories. Game-session state (player, calendar, action points)
    /// is exposed through the per-screen ViewModel — never read from a
    /// `@Environment(DefaultGameService.self)` binding.
    @ViewBuilder
    func gameContainerEnvironment(_ gameContainer: ElfGameContainer?) -> some View {
        if let gameContainer {
            self.environment(gameContainer)
        } else {
            self
        }
    }
}
