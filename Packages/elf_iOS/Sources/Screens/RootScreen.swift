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

    /// Injects `ElfGameContainer` and the active `DefaultGameService` (when present)
    /// into the environment so screens can read game state directly with
    /// `@Environment(DefaultGameService.self)`.
    @ViewBuilder
    func gameContainerEnvironment(_ gameContainer: ElfGameContainer?) -> some View {
        if let gameContainer {
            if let gameService = gameContainer.activeGameService {
                self
                    .environment(gameContainer)
                    .environment(gameService)
            } else {
                self.environment(gameContainer)
            }
        } else {
            self
        }
    }
}
