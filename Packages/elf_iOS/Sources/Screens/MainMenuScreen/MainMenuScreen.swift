//
//  MainMenuScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import elf_Kit
import SwiftUI

public struct MainMenuScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    public init() {}

    public var body: some View {
        MainMenuScreenContent(
            viewModel: container.makeMainMenuViewModel()
        )
    }
}

#Preview {
    MainMenuScreen()
        .environment(ElfAppDependencyContainer())
}
