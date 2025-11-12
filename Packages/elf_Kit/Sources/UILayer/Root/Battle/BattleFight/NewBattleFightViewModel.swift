//
//  NewBattleFightViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Foundation

@Observable
public final class NewBattleFightViewModel {

    // MARK: - Dependencies

    private let navigationManager: any NavigationManaging

    // MARK: - State

    public let userHeroConfiguration: HeroConfiguration
    public let enemyHeroConfiguration: HeroConfiguration

    // MARK: - Initialization

    public init(
        userHeroConfiguration: HeroConfiguration,
        enemyHeroConfiguration: HeroConfiguration,
        navigationManager: any NavigationManaging
    ) {
        self.userHeroConfiguration = userHeroConfiguration
        self.enemyHeroConfiguration = enemyHeroConfiguration
        self.navigationManager = navigationManager
    }

    // MARK: - Actions

    public func backButtonAction() {
        navigationManager.pop()
    }

    public func backToMainButtonAction() {
        navigationManager.popToRoot()
    }
}
