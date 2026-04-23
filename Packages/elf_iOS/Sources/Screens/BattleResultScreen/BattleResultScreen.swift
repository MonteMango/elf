//
//  BattleResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import elf_Kit
import SwiftUI

struct BattleResultScreen: View {
    let result: ManualBattleResult

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        BattleResultScreenContent(
            viewModel: BattleResultViewModel(result: result)
        )
    }
}
