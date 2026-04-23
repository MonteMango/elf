//
//  HuntScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import elf_Kit
import SwiftUI

struct HuntScreen: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let session = coordinator.sessionModel {
            HuntScreenContent(
                viewModel: session.makeHuntViewModel(),
                dayStateViewModel: session.dayState
            )
        }
    }
}
