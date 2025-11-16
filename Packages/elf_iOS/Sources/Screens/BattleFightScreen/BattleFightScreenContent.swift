//
//  BattleFightScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 15.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleFightScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: BattleFightViewModel

    internal init(viewModel: BattleFightViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    internal var body: some View {
        VStack(spacing: 30) {
            Text("BattleFightScreen")
        }
        .onChange(of: viewModel.battleEnded) { _, ended in
            if ended {
                router.popToRoot()
            }
        }
    }
}
