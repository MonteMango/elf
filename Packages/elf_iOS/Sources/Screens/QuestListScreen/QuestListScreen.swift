//
//  QuestListScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct QuestListScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        QuestListScreenContent(
            viewModel: gameContainer.makeQuestListViewModel(),
            dayStateViewModel: gameContainer.requireGameDayStateViewModel()
        )
    }
}
