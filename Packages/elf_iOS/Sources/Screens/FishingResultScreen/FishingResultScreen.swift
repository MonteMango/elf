//
//  FishingResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct FishingResultScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer
    let result: FishingResult

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        FishingResultScreenContent(
            viewModel: gameContainer.makeFishingResultViewModel(result: result)
        )
    }
}
