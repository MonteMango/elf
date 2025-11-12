//
//  MainMenuScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import elf_Kit
import SwiftUI

public struct MainMenuScreen: View {
    @Environment(\.navigationManager) private var navigationManager

    public init() {}

    public var body: some View {
        VStack(spacing: 30) {
            Button("Start game") {
                print("Main menu")
            }
            Button("Battle") {
                navigationManager.push(AppRoute.battleSetup)
            }
        }
    }
}

#Preview {
    MainMenuScreen()
        .environment(\.navigationManager, AppNavigationManager())
}
