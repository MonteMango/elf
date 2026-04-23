//
//  ForagingResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct ForagingResultScreen: View {
    let result: ForagingResult

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ForagingResultScreenContent(
            viewModel: ForagingResultViewModel(result: result)
        )
    }
}
