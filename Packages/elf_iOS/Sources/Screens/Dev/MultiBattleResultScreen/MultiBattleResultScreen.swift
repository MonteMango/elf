//
//  MultiBattleResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import elf_Kit
import SwiftUI

internal struct MultiBattleResultScreen: View {
    @Environment(\.dismiss) private var dismiss

    let battle: Battle

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        MultiBattleResultScreenContent(
            viewModel: MultiBattleViewModel(
                battle: battle,
                totalBattles: PerfTestConfig.multiBattleCount
            ),
            onClose: { dismiss() }
        )
    }
}
