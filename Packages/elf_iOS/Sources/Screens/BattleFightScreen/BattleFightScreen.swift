//
//  BattleFightScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleFightScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    let battle: Battle

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        BattleFightScreenContent(
            viewModel: BattleFightViewModel(
                battle: battle,
                gameService: gameContainer.sessionModel?.gameService
            )
        )
    }
}
