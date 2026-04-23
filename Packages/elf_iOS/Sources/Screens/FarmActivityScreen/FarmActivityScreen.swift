//
//  FarmActivityScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct FarmActivityScreen: View {
    @Environment(AppCoordinator.self) private var coordinator

    let activity: FarmActivity

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let session = coordinator.sessionModel {
            FarmActivityScreenContent(
                viewModel: session.makeFarmActivityViewModel(activity: activity),
                dayStateViewModel: session.dayState
            )
        }
    }
}
