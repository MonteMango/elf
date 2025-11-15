//
//  SelectHeroItemScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import SwiftUI
import elf_Kit
import Combine

internal struct SelectHeroItemScreen: View {
    @Environment(ElfAppDependencyContainer.self) private var container

    private let heroType: HeroType
    private let heroItemType: HeroItemType
    private let currentItemId: UUID?

    internal init(heroType: HeroType, heroItemType: HeroItemType, currentItemId: UUID?) {
        self.heroType = heroType
        self.heroItemType = heroItemType
        self.currentItemId = currentItemId
    }

    internal var body: some View {
        SelectHeroItemScreenContent(
            viewModel: container.makeSelectHeroItemViewModel(
                heroType: heroType,
                heroItemType: heroItemType,
                currentItemId: currentItemId
            ),
            heroItemType: heroItemType
        )
    }
}
