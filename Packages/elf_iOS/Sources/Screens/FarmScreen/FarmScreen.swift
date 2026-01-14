//
//  FarmScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import elf_Kit
import SwiftUI

struct FarmScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    var body: some View {
        FarmScreenContent(viewModel: container.makeFarmViewModel())
    }
}
