//
//  GameDayScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import SwiftUI

internal struct GameDayScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    internal init() {}

    internal var body: some View {
        if gameContainer.activeGameService != nil {
            GameDayScreenContent(
                viewModel: gameContainer.makeGameDayViewModel(),
                inventoryViewModel: gameContainer.makeInventoryViewModel(),
                dayStateViewModel: gameContainer.requireGameDayStateViewModel()
            )
        }
    }
}
