//
//  CraftScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct CraftScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    var body: some View {
        CraftScreenContent(viewModel: container.makeCraftViewModel())
    }
}
