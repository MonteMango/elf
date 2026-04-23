//
//  GameDayScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import SwiftUI

internal struct GameDayScreen: View {
    @Environment(AppCoordinator.self) private var coordinator

    internal init() {}

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let session = coordinator.sessionModel {
            GameDayScreenContent(
                viewModel: session.makeGameDayViewModel(),
                inventoryViewModel: session.makeInventoryViewModel(),
                dayStateViewModel: session.dayState
            )
        }
    }
}
