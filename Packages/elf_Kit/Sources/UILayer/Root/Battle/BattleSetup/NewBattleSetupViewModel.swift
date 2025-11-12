//
//  NewBattleSetupViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Foundation

@Observable
public final class NewBattleSetupViewModel {

    // MARK: - Dependencies

    private let navigationManager: any NavigationManaging
    private let itemsRepository: ItemsRepository
    private let attributeService: AttributeService
    private let armorService: ArmorService
    private let damageService: DamageService

    // MARK: - State

    public var playerHeroConfiguration: HeroConfiguration = HeroConfiguration()
    public var botHeroConfiguration: HeroConfiguration = HeroConfiguration()

    // MARK: - Initialization

    public init(
        navigationManager: any NavigationManaging,
        itemsRepository: ItemsRepository,
        attributeService: AttributeService,
        armorService: ArmorService,
        damageService: DamageService
    ) {
        self.navigationManager = navigationManager
        self.itemsRepository = itemsRepository
        self.attributeService = attributeService
        self.armorService = armorService
        self.damageService = damageService
    }

    // MARK: - Actions

    public func backButtonAction() {
        navigationManager.pop()
    }

    public func fightButtonAction() {
        navigationManager.push(
            AppRoute.battleFight(
                user: playerHeroConfiguration,
                enemy: botHeroConfiguration
            )
        )
    }
}
