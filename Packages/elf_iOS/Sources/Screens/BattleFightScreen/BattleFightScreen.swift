//
//  BattleFightScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleFightScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    let battle: Battle

    internal var body: some View {
        BattleFightScreenContent(
            viewModel: container.makeBattleFightViewModel(battle: battle)
        )
    }
}
