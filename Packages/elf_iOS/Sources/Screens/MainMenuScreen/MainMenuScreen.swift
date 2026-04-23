//
//  MainMenuScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct MainMenuScreen: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppCoordinator.self) private var coordinator
    @State private var viewModel: MainMenuViewModel

    init() {
        self._viewModel = State(initialValue: MainMenuViewModel())
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 30) {
            // Continue button — appears when a save exists.
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
            .buttonStyle(.elfPrimary)

            Button("Battle") {
                router.navigate(to: .battleSetup)
            }
            .buttonStyle(.elfPrimary)
        }
        .onChange(of: viewModel.loadedGame) { _, newGame in
            if let game = newGame {
                coordinator.startGame(game, playTime: viewModel.loadedPlayTime)
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
    @Previewable @State var coordinator: AppCoordinator?
    @Previewable @State var router = AppRouter()

    if let coordinator {
        NavigationStack(path: $router.navigationPath) {
            MainMenuScreen()
                .environment(router)
                .environment(coordinator)
        }
    } else {
        ProgressView()
            .task {
                await DependencyBootstrap.run()
                coordinator = AppCoordinator()
            }
    }
}
