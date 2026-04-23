//
//  HuntScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import elf_Kit
import SwiftUI

struct HuntScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let session = gameContainer.sessionModel {
            HuntScreenContent(
                viewModel: session.makeHuntViewModel(),
                dayStateViewModel: session.dayState
            )
        }
    }
}
