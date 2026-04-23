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
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let session = gameContainer.sessionModel {
            GameDayScreenContent(
                viewModel: session.makeGameDayViewModel(),
                inventoryViewModel: gameContainer.makeInventoryViewModel(),
                dayStateViewModel: session.dayState
            )
        }
    }
}
