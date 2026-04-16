//
//  QuestScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct QuestScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    let questId: QuestID
    let ownerImageName: String

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        QuestScreenContent(
            viewModel: gameContainer.makeQuestViewModel(questId: questId),
            zoomSourceID: ownerImageName
        )
    }
}
