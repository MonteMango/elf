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
    @State private var viewModel: MainMenuViewModel

    internal init(viewModel: MainMenuViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    internal var body: some View {
        VStack(spacing: 30) {
            // Continue button (only shown if save exists)
            if viewModel.hasSavedGame {
                Button {
                    Task {
                        await viewModel.loadGame()
                    }
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
                router.navigate(to: .gameSession(game, playTime: viewModel.loadedPlayTime))
                viewModel.loadedGame = nil
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
        .onAppear {
            viewModel.refreshSaveStatus()
        }
    }
}

#Preview {
    @Previewable @State var router = AppRouter()
    let container = ElfAppDependencyContainer()

    NavigationStack(path: $router.navigationPath) {
        MainMenuScreenContent(
            viewModel: container.makeMainMenuViewModel()
        )
        .environment(router)
    }
}
