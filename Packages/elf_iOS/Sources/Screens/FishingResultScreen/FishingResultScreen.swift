//
//  FishingResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct FishingResultScreen: View {
    let result: FishingResult

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        FishingResultScreenContent(
            viewModel: FishingResultViewModel(result: result)
        )
    }
}
