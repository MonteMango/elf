//
//  FarmScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import elf_Kit
import SwiftUI

struct FarmScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    var body: some View {
        FarmScreenContent(viewModel: gameContainer.makeFarmViewModel())
    }
}
