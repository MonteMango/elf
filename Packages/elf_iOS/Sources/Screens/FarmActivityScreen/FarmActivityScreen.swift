//
//  FarmActivityScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct FarmActivityScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    let activity: FarmActivity

    var body: some View {
        FarmActivityScreenContent(
            viewModel: gameContainer.makeFarmActivityViewModel(activity: activity),
            dayStateViewModel: gameContainer.requireGameDayStateViewModel()
        )
    }
}
