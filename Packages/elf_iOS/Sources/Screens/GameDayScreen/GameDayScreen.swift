//
//  GameDayScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import SwiftUI

internal struct GameDayScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    let character: PlayerCharacter

    internal init(character: PlayerCharacter) {
        self.character = character
    }

    internal var body: some View {
        GameDayScreenContent(
            viewModel: container.makeGameDayViewModel(character: character)
        )
    }
}
