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
        BattleFightScreenContent(
            viewModel: gameContainer.makeBattleFightViewModel(battle: battle)
        )
    }
}
