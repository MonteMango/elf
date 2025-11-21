//
//  MultiBattleResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import elf_Kit
import SwiftUI

internal struct MultiBattleResultScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container
    @Environment(\.dismiss) private var dismiss

    let battle: Battle

    internal var body: some View {
        MultiBattleResultScreenContent(
            viewModel: container.makeMultiBattleViewModel(battle: battle),
            onClose: { dismiss() }
        )
    }
}
