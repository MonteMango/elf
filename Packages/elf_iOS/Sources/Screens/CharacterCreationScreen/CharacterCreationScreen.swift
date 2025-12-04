//
//  CharacterCreationScreen.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import elf_Kit
import SwiftUI

struct CharacterCreationScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    var body: some View {
        CharacterCreationScreenContent(
            viewModel: container.makeCharacterCreationViewModel()
        )
    }
}
