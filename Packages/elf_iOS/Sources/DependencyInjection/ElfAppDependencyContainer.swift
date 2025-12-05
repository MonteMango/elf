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
    public let critService: CritService
    public let weaponValidator: WeaponValidator
    public let elfHeroBuilder: ElfHeroBuilder
    public let fightStyleDescriptionService: FightStyleDescriptionService
    public let nameSuggestionService: CharacterNameSuggestionService
    public let elfInfoFactory: ElfInfoFactory
    public let houseService: HouseService
    public let gameRepository: GameRepository

    // Battle services
    public let botAI: BotAIService
    public let combatCalculator: CombatCalculator
    public let battleLogger: BattleLogger
    public let debugBattleLogger: DebugBattleLogger
    public let statisticsParser: BattleStatisticsParser
    public let battleSimulationService: BattleSimulationService

    // MARK: - Game Session State

    /// Currently active game service (nil when not in game)
    public private(set) var activeGameService: GameService?

    // MARK: - Initialization

    public init() {
        let itemsRepository = ElfItemsRepository()
        let attributeService = ElfAttributeService(itemsRepository: itemsRepository)
        let elfInfoFactory = DefaultElfInfoFactory(attributeService: attributeService)

        self.itemsRepository = itemsRepository
        self.attributeService = attributeService
        self.elfInfoFactory = elfInfoFactory
        self.armorService = ElfArmorService(itemsRepository: itemsRepository)

        // Initialize debug logger based on build configuration
        #if DEBUG
        // Configure which categories to log in debug builds
        let debugLogCategories: Set<DebugBattleLogCategory> = [
//            .roundStart,
//            .strengthDamage,
//            .weaponDamage,
//            .dodgeCalculation,
//            .critCalculation,
//            .bodyPartCalculation,
//            .roundEnd
        ]
        self.debugBattleLogger = ConsoleDebugBattleLogger(categories: debugLogCategories)
        #else
        self.debugBattleLogger = NoOpDebugBattleLogger()
        #endif

        self.damageService = ElfDamageService(
            itemsRepository: itemsRepository
        )

        // Initialize dodge service with distribution strategy
        let dodgeDistributionStrategy = ElfDodgeDistributionStrategy()
        self.dodgeService = ElfDodgeService(distributionStrategy: dodgeDistributionStrategy)

        // Initialize crit service with distribution strategy
        let critDistributionStrategy = ElfCritDistributionStrategy()
        self.critService = ElfCritService(distributionStrategy: critDistributionStrategy)

        self.weaponValidator = ElfWeaponValidator(itemsRepository: itemsRepository)
        self.elfHeroBuilder = DefaultElfHeroBuilder(itemsRepository: itemsRepository, armorService: self.armorService)

        // Initialize character creation services
        self.fightStyleDescriptionService = DefaultFightStyleDescriptionService()
        self.nameSuggestionService = DefaultCharacterNameSuggestionService()
        self.houseService = DefaultHouseService(elfInfoFactory: elfInfoFactory)

        // Initialize persistence
        self.gameRepository = FileGameRepository()

        // Initialize battle services
        self.botAI = ElfRandomBotAI()
        self.combatCalculator = ElfCombatCalculator(
            damageService: self.damageService,
            dodgeService: self.dodgeService,
            critService: self.critService,
            debugLogger: self.debugBattleLogger
        )
        self.battleLogger = ElfBattleLogger()
        self.statisticsParser = ElfBattleStatisticsParser()
        self.battleSimulationService = ElfBattleSimulationService(
            attributeService: self.attributeService,
            botAI: self.botAI,
            combatCalculator: self.combatCalculator,
            damageService: self.damageService,
            statisticsParser: self.statisticsParser
        )
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
            battleLogger: self.battleLogger,
            debugLogger: self.debugBattleLogger
        )
    }

    @MainActor
    public func makeAutoBattleViewModel(battle: Battle) -> AutoBattleViewModel {
        return AutoBattleViewModel(
            battle: battle,
            attributeService: self.attributeService,
            botAI: self.botAI,
            combatCalculator: self.combatCalculator,
            damageService: self.damageService,
            statisticsParser: self.statisticsParser
        )
    }

    @MainActor
    public func makeMultiBattleViewModel(battle: Battle) -> MultiBattleViewModel {
        return MultiBattleViewModel(
            battle: battle,
            battleSimulationService: self.battleSimulationService
        )
    }

    @MainActor
    public func makeMainMenuViewModel() -> MainMenuViewModel {
        return MainMenuViewModel(
            itemsRepository: self.itemsRepository,
            gameRepository: self.gameRepository
        )
    }

    @MainActor
    public func makeCharacterCreationViewModel() -> CharacterCreationViewModel {
        let nameValidator = DefaultCharacterNameValidator()
        let characterBuilder = DefaultCharacterBuilder()

        return CharacterCreationViewModel(
            attributeService: self.attributeService,
            nameValidator: nameValidator,
            characterBuilder: characterBuilder,
            fightStyleDescriptionService: self.fightStyleDescriptionService,
            nameSuggestionService: self.nameSuggestionService,
            houseService: self.houseService,
            elfInfoFactory: self.elfInfoFactory,
            gameRepository: self.gameRepository
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

    @MainActor
    public func makeGameDayViewModel(game: Game, playTime: TimeInterval = 0) -> GameDayViewModel {
        let gameService = DefaultGameService(
            game: game,
            gameRepository: self.gameRepository,
            playTime: playTime
        )
        self.activeGameService = gameService
        return GameDayViewModel(gameService: gameService)
    }

    // MARK: - Game Session Management

    /// Clears active game service (called when exiting game)
    @MainActor
    public func endGame() {
        self.activeGameService = nil
    }

    /// Saves active game if exists (called on app background)
    @MainActor
    public func saveActiveGameIfNeeded() async {
        guard let gameService = activeGameService else { return }
        try? await gameService.saveGame()
    }
}
