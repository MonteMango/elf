//
//  BattleSetupScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleSetupScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    internal init() {}

    internal var body: some View {
        BattleSetupScreenContent(
            viewModel: gameContainer.makeBattleSetupViewModel()
        )
    }
}
