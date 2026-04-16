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
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        MainMenuScreenContent(
            viewModel: appContainer.makeMainMenuViewModel()
        )
    }
}
