//
//  MainMenuScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import SwiftUI

internal struct MainMenuScreen: View {
    @Environment(\.navigationManager) private var navigationManager
    
    internal var body: some View {
        VStack(spacing: 30) {
            Button("Start game") {
                print("Main menu")
            }
            Button("Battle") {
                navigationManager.push(.battleSetup)
            }
        }
    }
}

#Preview {
    MainMenuScreen()
        .environment(AppNavigationManager.shared)
}
