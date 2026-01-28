//
//  MiningResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct MiningResultScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container
    let result: MiningResult

    var body: some View {
        MiningResultScreenContent(
            viewModel: container.makeMiningResultViewModel(result: result)
        )
    }
}
