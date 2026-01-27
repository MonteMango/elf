//
//  FishingResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct FishingResultScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container
    let result: FishingResult

    var body: some View {
        FishingResultScreenContent(
            viewModel: container.makeFishingResultViewModel(result: result)
        )
    }
}
