//
//  BattleSetupScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import SwiftUI

internal struct BattleSetupScreen: View {
    @Environment(\.navigationManager) private var navigationManager

    internal init() {}

    internal var body: some View {
        VStack(spacing: 30) {
            Text("BattleSetupScreen")

            Button("Fight") {
                navigationManager.push(.battleFight)
            }

            Button("Back") {
                navigationManager.pop()
            }
        }
    }
}
