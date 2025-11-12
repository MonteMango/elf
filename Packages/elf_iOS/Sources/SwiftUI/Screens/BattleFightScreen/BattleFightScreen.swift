//
//  BattleFightScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleFightScreen: View {
    @State private var viewModel: NewBattleFightViewModel

    internal init(viewModel: NewBattleFightViewModel) {
        self.viewModel = viewModel
    }

    internal var body: some View {
        VStack(spacing: 30) {
            Text("BattleFightScreen")

            Button("Back") {
                viewModel.backButtonAction()
            }

            Button("Back to Main") {
                viewModel.backToMainButtonAction()
            }
        }
    }
}
