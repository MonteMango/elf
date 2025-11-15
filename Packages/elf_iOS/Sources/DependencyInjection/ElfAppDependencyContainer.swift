//
//  ElfAppDependencyContainer.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import Foundation

@Observable
public final class ElfAppDependencyContainer {

    // MARK: - Long-lived dependencies

    public let dataLoader: DataLoader
    public let itemsRepository: ItemsRepository
    public let attributeService: AttributeService
    public let armorService: ArmorService
    public let damageService: DamageService
    public let weaponValidator: WeaponValidator

    // MARK: - Initialization

    public init() {
        self.dataLoader = ElfDataLoader()
        self.itemsRepository = ElfItemsRepository(dataLoader: self.dataLoader)
        self.attributeService = ElfAttributeService(itemsRepository: self.itemsRepository)
        self.armorService = ElfArmorService(itemsRepository: self.itemsRepository)
        self.damageService = ElfDamageService()
        self.weaponValidator = ElfWeaponValidator(itemsRepository: self.itemsRepository)
    }

    // MARK: - ViewModel Factories

    @MainActor
    public func makeBattleSetupViewModel() -> BattleSetupViewModel {
        return BattleSetupViewModel(
            itemsRepository: self.itemsRepository,
            attributeService: self.attributeService,
            armorService: self.armorService,
            damageService: self.damageService,
            weaponValidator: self.weaponValidator
        )
    }

    public func makeBattleFightViewModel(
        userHeroConfiguration: HeroConfiguration,
        enemyHeroConfiguration: HeroConfiguration
    ) -> BattleFightViewModel {
        return BattleFightViewModel(
            userHeroConfiguration: userHeroConfiguration,
            enemyHeroConfiguration: enemyHeroConfiguration
        )
    }

    @MainActor
    public func makeMainMenuViewModel() -> MainMenuViewModel {
        return MainMenuViewModel(
            itemsRepository: self.itemsRepository
        )
    }

    @MainActor
    public func makeSelectHeroItemViewModel(
        heroType: HeroType,
        heroItemType: HeroItemType,
        currentItemId: UUID?
    ) -> SelectHeroItemViewModel {
        return SelectHeroItemViewModel(
            heroType: heroType,
            heroItemType: heroItemType,
            currentItemId: currentItemId,
            itemsRepository: self.itemsRepository
        )
    }
}
