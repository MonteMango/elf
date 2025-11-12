//
//  BattleSetupScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleSetupScreen: View {
    @State private var viewModel: NewBattleSetupViewModel

    internal init(viewModel: NewBattleSetupViewModel) {
        self.viewModel = viewModel
    }

    internal var body: some View {
        VStack(spacing: 30) {
            Text("BattleSetupScreen")

            Button("Fight") {
                viewModel.fightButtonAction()
            }

            Button("Back") {
                viewModel.backButtonAction()
            }
        }
    }
}
