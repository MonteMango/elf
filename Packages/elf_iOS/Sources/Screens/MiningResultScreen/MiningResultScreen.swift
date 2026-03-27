//
//  MiningResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct MiningResultScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer
    let result: MiningResult

    var body: some View {
        MiningResultScreenContent(
            viewModel: gameContainer.makeMiningResultViewModel(result: result)
        )
    }
}
