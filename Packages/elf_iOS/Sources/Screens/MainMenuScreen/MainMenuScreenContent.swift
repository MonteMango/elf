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
            NavigationLink(value: AppRoute.battleSetup) {
                Text("Battle")
            }
            .buttonStyle(.borderedProminent)

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
    MainMenuScreenContent(
        viewModel: MainMenuViewModel(
            itemsRepository: ElfItemsRepository(dataLoader: ElfDataLoader())
        )
    )
}
