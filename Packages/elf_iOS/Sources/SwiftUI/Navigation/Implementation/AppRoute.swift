//
//  AppRoute.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

// MARK: - View Mapping Extension

extension AppRoute {

    @ViewBuilder
    public func view(
        container: NewElfAppDependencyContainer,
        navigationManager: AppNavigationManager
    ) -> some View {
        switch self {
        case .mainMenu:
            let viewModel = container.makeMainMenuViewModel(navigationManager: navigationManager)
            MainMenuScreen(viewModel: viewModel)
        case .battleSetup:
            let viewModel = container.makeBattleSetupViewModel(navigationManager: navigationManager)
            BattleSetupScreen(viewModel: viewModel)
        case .battleFight(let user, let enemy):
            let viewModel = container.makeBattleFightViewModel(
                userHeroConfiguration: user,
                enemyHeroConfiguration: enemy,
                navigationManager: navigationManager
            )
            BattleFightScreen(viewModel: viewModel)
        case .selectHeroItem(let heroType, let heroItemType, let currentId, let callback):
            let viewModel = container.makeSelectHeroItemViewModel(
                heroType: heroType,
                heroItemType: heroItemType,
                currentItemId: currentId,
                navigationManager: navigationManager,
                onItemSelected: callback
            )
            SelectHeroItemScreen(viewModel: viewModel)
        }
    }
}
