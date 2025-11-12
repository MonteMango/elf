//
//  BattleFightScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import SwiftUI

internal struct BattleFightScreen: View {
    @Environment(\.navigationManager) private var navigationManager

    internal init() {}

    internal var body: some View {
        VStack(spacing: 30) {
            Text("BattleFightScreen")

            Button("Back") {
                navigationManager.pop()
            }

            Button("Back to Main") {
                navigationManager.popToRoot()
            }
        }
    }
}
