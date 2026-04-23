//
//  AutoBattleResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import elf_Kit
import SwiftUI

internal struct AutoBattleResultScreen: View {
    @Environment(\.dismiss) private var dismiss

    let battle: Battle

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        AutoBattleResultScreenContent(
            viewModel: AutoBattleViewModel(battle: battle),
            onClose: { dismiss() }
        )
    }
}
