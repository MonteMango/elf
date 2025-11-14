//
//  NewElfAppDependencyContainer.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import Foundation

@Observable
public final class NewElfAppDependencyContainer {

    // MARK: - Long-lived dependencies

    public let dataLoader: DataLoader
    public let itemsRepository: ItemsRepository
    public let attributeService: AttributeService
    public let armorService: ArmorService
    public let damageService: DamageService

    // MARK: - Initialization

    public init() {
        self.dataLoader = ElfDataLoader()
        self.itemsRepository = ElfItemsRepository(dataLoader: self.dataLoader)
        self.attributeService = ElfAttributeService(itemsRepository: self.itemsRepository)
        self.armorService = ElfArmorService(itemsRepository: self.itemsRepository)
        self.damageService = ElfDamageService()
    }

    // MARK: - ViewModel Factories

    public func makeBattleSetupViewModel(navigationManager: any NavigationManaging) -> NewBattleSetupViewModel {
        return NewBattleSetupViewModel(
            navigationManager: navigationManager,
            itemsRepository: self.itemsRepository,
            attributeService: self.attributeService,
            armorService: self.armorService,
            damageService: self.damageService
        )
    }

    public func makeBattleFightViewModel(
        userHeroConfiguration: HeroConfiguration,
        enemyHeroConfiguration: HeroConfiguration,
        navigationManager: any NavigationManaging
    ) -> NewBattleFightViewModel {
        return NewBattleFightViewModel(
            userHeroConfiguration: userHeroConfiguration,
            enemyHeroConfiguration: enemyHeroConfiguration,
            navigationManager: navigationManager
        )
    }

    public func makeMainMenuViewModel(navigationManager: any NavigationManaging) -> MainMenuViewModel {
        return MainMenuViewModel(
            navigationManager: navigationManager,
            itemsRepository: self.itemsRepository
        )
    }
}
