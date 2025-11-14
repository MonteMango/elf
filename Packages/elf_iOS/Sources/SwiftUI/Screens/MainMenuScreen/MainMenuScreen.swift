//
//  MainMenuScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import elf_Kit
import SwiftUI

public struct MainMenuScreen: View {
    @State private var viewModel: MainMenuViewModel

    public init(viewModel: MainMenuViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 30) {
            Button("Start game") {
                viewModel.startGameAction()
            }
            Button("Battle") {
                viewModel.battleAction()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}

#Preview {
    MainMenuScreen(
        viewModel: MainMenuViewModel(
            navigationManager: AppNavigationManager(),
            itemsRepository: ElfItemsRepository(dataLoader: ElfDataLoader())
        )
    )
}
