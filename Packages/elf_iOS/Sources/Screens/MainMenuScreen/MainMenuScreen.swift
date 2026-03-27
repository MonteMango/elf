//
//  MainMenuScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import SwiftUI

struct MainMenuScreen: View {
    @Environment(ElfAppContainer.self) private var appContainer

    var body: some View {
        MainMenuScreenContent(
            viewModel: appContainer.makeMainMenuViewModel()
        )
    }
}
