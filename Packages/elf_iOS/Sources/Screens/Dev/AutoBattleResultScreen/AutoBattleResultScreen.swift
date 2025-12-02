//
//  AutoBattleResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import elf_Kit
import SwiftUI

internal struct AutoBattleResultScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container
    @Environment(\.dismiss) private var dismiss

    let battle: Battle

    internal var body: some View {
        AutoBattleResultScreenContent(
            viewModel: container.makeAutoBattleViewModel(battle: battle),
            onClose: { dismiss() }
        )
    }
}
