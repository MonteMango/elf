//
//  CraftScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct CraftScreen: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let session = coordinator.sessionModel {
            CraftScreenContent(viewModel: session.makeCraftViewModel())
        }
    }
}
