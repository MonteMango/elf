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

    let game: Game
    let playTime: TimeInterval

    internal init(game: Game, playTime: TimeInterval = 0) {
        self.game = game
        self.playTime = playTime
    }

    internal var body: some View {
        GameDayScreenContent(
            viewModel: container.makeGameDayViewModel(game: game, playTime: playTime)
        )
    }
}
