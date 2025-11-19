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

    public let itemsRepository: ItemsRepository
    public let attributeService: AttributeService
    public let armorService: ArmorService
    public let damageService: DamageService
    public let dodgeService: DodgeService
    public let weaponValidator: WeaponValidator
    public let elfHeroBuilder: ElfHeroBuilder

    // Battle services
    public let botAI: BotAIService
    public let combatCalculator: CombatCalculator
    public let battleLogger: BattleLogger

    // MARK: - Initialization

    public init() {
        let itemsRepository = ElfItemsRepository()

        self.itemsRepository = itemsRepository
        self.attributeService = ElfAttributeService(itemsRepository: itemsRepository)
        self.armorService = ElfArmorService(itemsRepository: itemsRepository)
        self.damageService = ElfDamageService(itemsRepository: itemsRepository)

        // Initialize dodge service with distribution strategy
        let dodgeDistributionStrategy = ElfDodgeDistributionStrategy()
        self.dodgeService = ElfDodgeService(distributionStrategy: dodgeDistributionStrategy)

        self.weaponValidator = ElfWeaponValidator(itemsRepository: itemsRepository)
        self.elfHeroBuilder = ElfElfHeroBuilder(itemsRepository: itemsRepository, armorService: self.armorService)

        // Initialize battle services
        self.botAI = RandomBotAI()
        self.combatCalculator = BasicCombatCalculator(
            damageService: self.damageService,
            dodgeService: self.dodgeService
        )
        self.battleLogger = DefaultBattleLogger()
    }

    // MARK: - ViewModel Factories

    @MainActor
    public func makeBattleSetupViewModel() -> BattleSetupViewModel {
        return BattleSetupViewModel(
            itemsRepository: self.itemsRepository,
            attributeService: self.attributeService,
            armorService: self.armorService,
            damageService: self.damageService,
            weaponValidator: self.weaponValidator,
            elfHeroBuilder: self.elfHeroBuilder
        )
    }

    @MainActor
    public func makeBattleFightViewModel(battle: Battle) -> BattleFightViewModel {
        return BattleFightViewModel(
            battle: battle,
            attributeService: self.attributeService,
            damageService: self.damageService,
            botAI: self.botAI,
            combatCalculator: self.combatCalculator,
            battleLogger: self.battleLogger
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
