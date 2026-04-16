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
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        FarmActivityScreenContent(
            viewModel: gameContainer.makeFarmActivityViewModel(activity: activity),
            dayStateViewModel: gameContainer.requireGameDayStateViewModel()
        )
    }
}
