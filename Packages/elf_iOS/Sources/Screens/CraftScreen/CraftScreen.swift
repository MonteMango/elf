//
//  CraftScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct CraftScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    var body: some View {
        CraftScreenContent(viewModel: gameContainer.makeCraftViewModel())
    }
}
