//
//  BattleSetupScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleSetupScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    internal init() {}

    internal var body: some View {
        BattleSetupScreenContent(
            viewModel: container.makeBattleSetupViewModel()
        )
    }
}

#Preview {
    NavigationStack {
        BattleSetupScreen()
            .environment(AppRouter())
            .environment(ElfAppDependencyContainer())
    }
}
