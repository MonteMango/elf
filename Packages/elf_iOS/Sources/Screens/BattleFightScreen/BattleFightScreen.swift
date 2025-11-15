//
//  BattleFightScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

internal struct BattleFightScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    private let userConfiguration: HeroConfiguration
    private let enemyConfiguration: HeroConfiguration

    internal init(userConfiguration: HeroConfiguration, enemyConfiguration: HeroConfiguration) {
        self.userConfiguration = userConfiguration
        self.enemyConfiguration = enemyConfiguration
    }

    internal var body: some View {
        BattleFightScreenContent(
            viewModel: container.makeBattleFightViewModel(
                userHeroConfiguration: userConfiguration,
                enemyHeroConfiguration: enemyConfiguration
            )
        )
    }
}
