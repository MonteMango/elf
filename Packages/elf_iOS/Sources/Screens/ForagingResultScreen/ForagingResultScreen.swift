//
//  ForagingResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct ForagingResultScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container
    let result: ForagingResult

    var body: some View {
        ForagingResultScreenContent(
            viewModel: container.makeForagingResultViewModel(result: result)
        )
    }
}
