//
//  MainMenuScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

internal struct MainMenuScreenContent: View {
    @Environment(AppRouter.self) private var router
    @Environment(ElfAppContainer.self) private var appContainer
    @State private var viewModel: MainMenuViewModel

    internal init(viewModel: MainMenuViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 30) {
            // Continue button — appears when game data loaded AND save exists
            if viewModel.hasSavedGame {
                Button {
                    Task { await viewModel.loadGame() }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Continue")
                    }
                }
                .buttonStyle(.elfPrimary)
                .disabled(viewModel.isLoading)
            }

            Button("New Game") {
                router.navigate(to: .characterCreation)
            }
            .buttonStyle(.elfPrimary(isEnabled: viewModel.isGameDataReady))
            .disabled(!viewModel.isGameDataReady)

            Button("Battle") {
                router.navigate(to: .battleSetup)
            }
            .buttonStyle(.elfPrimary(isEnabled: viewModel.isGameDataReady))
            .disabled(!viewModel.isGameDataReady)
        }
        // Covers the edge case where gameContainer is already loaded
        // before this view appears (e.g. navigating back to MainMenu).
        // onChange below only fires on transitions, not on initial state.
        .task {
            if let gc = appContainer.gameContainer {
                viewModel.onGameDataReady(gameRepository: gc.gameRepository)
            }
        }
        .onChange(of: appContainer.gameContainer != nil) { _, isReady in
            if isReady, let gameContainer = appContainer.gameContainer {
                viewModel.onGameDataReady(gameRepository: gameContainer.gameRepository)
            }
        }
        .onChange(of: viewModel.loadedGame) { _, newGame in
            if let game = newGame, let gameContainer = appContainer.gameContainer {
                gameContainer.startGameSession(game: game, playTime: viewModel.loadedPlayTime)
                router.navigate(to: .gameSession(game, playTime: viewModel.loadedPlayTime))
                viewModel.consumeLoadedGame()
            }
        }
        .alert("Load Error", isPresented: .init(
            get: { viewModel.loadError != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            if let error = viewModel.loadError {
                Text(error)
            }
        }
    }
}

#Preview {
    @Previewable @State var appContainer: ElfAppContainer?
    @Previewable @State var router = AppRouter()

    if let appContainer {
        NavigationStack(path: $router.navigationPath) {
            MainMenuScreenContent(viewModel: MainMenuViewModel())
                .environment(router)
                .environment(appContainer)
        }
    } else {
        ProgressView()
            .task {
                let container = ElfAppContainer()
                await container.createGameContainer()
                appContainer = container
            }
    }
}
