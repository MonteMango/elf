//
//  FarmActivityScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct FarmActivityScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    let activity: FarmActivity

    var body: some View {
        FarmActivityScreenContent(
            viewModel: container.makeFarmActivityViewModel(activity: activity)
        )
    }
}
