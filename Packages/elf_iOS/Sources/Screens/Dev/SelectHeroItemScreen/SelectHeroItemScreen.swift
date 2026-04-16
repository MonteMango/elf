//
//  SelectHeroItemScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import elf_Kit
import SwiftUI

internal struct SelectHeroItemScreen: View {
    @Environment(ElfGameContainer.self) private var gameContainer

    private let heroType: HeroType
    private let heroItemType: HeroItemType
    private let currentItemId: UUID?
    private let onEquip: (UUID?) -> Void

    internal init(
        heroType: HeroType,
        heroItemType: HeroItemType,
        currentItemId: UUID?,
        onEquip: @escaping (UUID?) -> Void
    ) {
        self.heroType = heroType
        self.heroItemType = heroItemType
        self.currentItemId = currentItemId
        self.onEquip = onEquip
    }

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        SelectHeroItemScreenContent(
            viewModel: gameContainer.makeSelectHeroItemViewModel(
                heroType: heroType,
                heroItemType: heroItemType,
                currentItemId: currentItemId
            ),
            heroItemType: heroItemType,
            onEquip: onEquip
        )
    }
}
