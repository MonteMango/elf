//
//  ForagingResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct ForagingResultScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer
    let result: ForagingResult

    var body: some View {
        ForagingResultScreenContent(
            viewModel: gameContainer.makeForagingResultViewModel(result: result)
        )
    }
}
