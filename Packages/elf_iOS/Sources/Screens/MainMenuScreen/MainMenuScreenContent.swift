//
//  MainMenuScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import elf_Kit
import SwiftUI

internal struct MainMenuScreenContent: View {
    @State private var viewModel: MainMenuViewModel

    internal init(viewModel: MainMenuViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    internal var body: some View {
        VStack(spacing: 30) {
            Button("New Game") {
                // TODO: Implement new game action
            }
            .buttonStyle(.borderedProminent)

            NavigationLink(value: AppRoute.battleSetup) {
                Text("Battle")
            }
            .buttonStyle(.borderedProminent)
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
