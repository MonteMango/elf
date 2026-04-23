//
//  BattleSetupScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleSetupScreen: View {

    internal init() {}

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        BattleSetupScreenContent(
            viewModel: BattleSetupViewModel()
        )
    }
}
