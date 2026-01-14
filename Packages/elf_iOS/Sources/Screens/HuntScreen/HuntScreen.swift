//
//  HuntScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import elf_Kit
import SwiftUI

struct HuntScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    var body: some View {
        HuntScreenContent(viewModel: container.makeHuntViewModel())
    }
}
