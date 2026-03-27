//
//  BattleResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import elf_Kit
import SwiftUI

struct BattleResultScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer
    let result: ManualBattleResult

    var body: some View {
        BattleResultScreenContent(
            viewModel: gameContainer.makeBattleResultViewModel(result: result)
        )
    }
}
