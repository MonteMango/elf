//
//  CharacterCreationScreen.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import elf_Kit
import SwiftUI

struct CharacterCreationScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        CharacterCreationScreenContent(
            viewModel: gameContainer.makeCharacterCreationViewModel()
        )
    }
}
