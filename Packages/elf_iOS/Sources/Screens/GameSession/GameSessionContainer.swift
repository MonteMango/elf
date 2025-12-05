//
//  GameSessionContainer.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 05.12.25.
//

import elf_Kit
import SwiftUI

/// Container for active game session
/// Handles cleanup when user exits game
public struct GameSessionContainer: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    let game: Game
    let playTime: TimeInterval

    public init(game: Game, playTime: TimeInterval) {
        self.game = game
        self.playTime = playTime
    }

    public var body: some View {
        GameDayScreen(game: game, playTime: playTime)
            .onDisappear {
                container.endGame()
            }
    }
}
