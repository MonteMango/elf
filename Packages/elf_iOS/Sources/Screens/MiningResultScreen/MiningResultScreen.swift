//
//  MiningResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct MiningResultScreen: View {
    let result: MiningResult

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        MiningResultScreenContent(
            viewModel: MiningResultViewModel(result: result)
        )
    }
}
