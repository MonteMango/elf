//
//  MainMenuScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import elf_Kit
import SwiftUI

struct MainMenuScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    init() {}

    public var body: some View {
        MainMenuScreenContent(
            viewModel: container.makeMainMenuViewModel()
        )
    }
}
