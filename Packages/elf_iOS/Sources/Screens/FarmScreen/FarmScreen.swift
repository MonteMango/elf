//
//  FarmScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import elf_Kit
import SwiftUI

struct FarmScreen: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let session = coordinator.sessionModel {
            FarmScreenContent(
                viewModel: session.makeFarmViewModel(),
                dayStateViewModel: session.dayState
            )
        }
    }
}
