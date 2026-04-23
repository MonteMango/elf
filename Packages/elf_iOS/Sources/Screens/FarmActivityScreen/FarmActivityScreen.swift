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
        if let session = gameContainer.sessionModel {
            FarmActivityScreenContent(
                viewModel: session.makeFarmActivityViewModel(activity: activity),
                dayStateViewModel: session.dayState
            )
        }
    }
}
