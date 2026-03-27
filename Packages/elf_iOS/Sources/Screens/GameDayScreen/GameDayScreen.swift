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

    let game: Game
    let playTime: TimeInterval

    internal init(game: Game, playTime: TimeInterval = 0) {
        self.game = game
        self.playTime = playTime
    }

    internal var body: some View {
        GameDayScreenContent(
            viewModel: gameContainer.makeGameDayViewModel(game: game, playTime: playTime),
            inventoryViewModel: gameContainer.makeInventoryViewModel()
        )
    }
}
