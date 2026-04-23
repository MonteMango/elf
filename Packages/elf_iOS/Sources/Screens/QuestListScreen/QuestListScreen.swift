//
//  QuestListScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct QuestListScreen: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let session = coordinator.sessionModel {
            QuestListScreenContent(
                viewModel: session.makeQuestListViewModel(),
                dayStateViewModel: session.dayState
            )
        }
    }
}
