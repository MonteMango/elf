//
//  ElfAppDependencyContainer.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import Foundation

// MARK: - Debug Logger Type Alias

#if DEBUG
public typealias DebugLoggerImpl = ConsoleDebugBattleLogger
#else
public typealias DebugLoggerImpl = NoOpDebugBattleLogger
#endif

@Observable
@MainActor
public final class ElfAppDependencyContainer {

    // MARK: - Long-lived dependencies (concrete types for static dispatch)

    public let itemsRepository: ElfItemsRepository
    public let attributeService: ElfAttributeService
    public let armorService: ElfArmorService
    public let damageService: ElfDamageService
    public let dodgeService: ElfDodgeService
    public let critService: ElfCritService
    public let weaponValidator: ElfWeaponValidator
    public let snapshotBuilder: DefaultCombatantSnapshotBuilder
    public let fightStyleDescriptionService: DefaultFightStyleDescriptionService
    public let nameSuggestionService: DefaultCharacterNameSuggestionService
    public let elfInfoFactory: DefaultElfInfoFactory
    public let houseService: DefaultHouseService
    public let gameRepository: FileGameRepository
    public let calendarService: DefaultCalendarService

    // Battle services (concrete types for static dispatch)
    public let botAI: ElfRandomBotAI
    public let snapshotCombatCalculator: ElfSnapshotCombatCalculator
    public let battleLogger: ElfBattleLogger
    public let debugBattleLogger: DebugLoggerImpl
    public let statisticsParser: ElfBattleStatisticsParser
    public let battleSimulationService: ElfBattleSimulationService
    public let combatRoundExecutor: ElfCombatRoundExecutor
    public let duelPairingService: RandomDuelPairingService
    public let monsterRepository: ElfMonsterRepository
    public let materialRepository: ElfMaterialRepository
    public let fishRepository: ElfFishRepository
    public let herbRepository: ElfHerbRepository
    public let oreRepository: ElfOreRepository

    // Hunt and drop services
    public let huntService: ElfHuntService
    public let dropService: DefaultDropService

    // Fishing service
    public let fishingService: DefaultFishingService

    // Foraging service
    public let foragingService: DefaultForagingService

    // Mining service
    public let miningService: DefaultMiningService

    // Farm activity service (unified for all farm activities)
    public let farmActivityService: DefaultFarmActivityService

    // Battle result calculation
    public let battleResultCalculator: DefaultBattleResultCalculator

    // Game initialization
    public let gameInitializationService: ElfGameInitializationService

    // MARK: - Game Session State

    /// Currently active game service (nil when not in game)
    /// @ObservationIgnored prevents view re-renders when this changes
    @ObservationIgnored
    public private(set) var activeGameService: DefaultGameService?

    // MARK: - Initialization

    public init() {
        let itemsRepository = ElfItemsRepository()
        let attributeService = ElfAttributeService(itemsRepository: itemsRepository)
        let elfInfoFactory = DefaultElfInfoFactory(
            attributeService: attributeService,
            itemsRepository: itemsRepository
        )
        let armorService = ElfArmorService(itemsRepository: itemsRepository)

        self.itemsRepository = itemsRepository
        self.attributeService = attributeService
        self.elfInfoFactory = elfInfoFactory
        self.armorService = armorService

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
        let debugBattleLogger = ConsoleDebugBattleLogger(categories: debugLogCategories)
        #else
        let debugBattleLogger = NoOpDebugBattleLogger()
        #endif
        self.debugBattleLogger = debugBattleLogger

        let damageService = ElfDamageService(itemsRepository: itemsRepository)
        self.damageService = damageService

        // Initialize dodge service with distribution strategy
        let dodgeDistributionStrategy = ElfDodgeDistributionStrategy()
        let dodgeService = ElfDodgeService(distributionStrategy: dodgeDistributionStrategy)
        self.dodgeService = dodgeService

        // Initialize crit service with distribution strategy
        let critDistributionStrategy = ElfCritDistributionStrategy()
        let critService = ElfCritService(distributionStrategy: critDistributionStrategy)
        self.critService = critService

        self.weaponValidator = ElfWeaponValidator(itemsRepository: itemsRepository)
        self.snapshotBuilder = DefaultCombatantSnapshotBuilder(
            itemsRepository: itemsRepository,
            armorService: armorService
        )

        // Initialize character creation services
        self.fightStyleDescriptionService = DefaultFightStyleDescriptionService()
        self.nameSuggestionService = DefaultCharacterNameSuggestionService()
        self.houseService = DefaultHouseService(elfInfoFactory: elfInfoFactory)

        // Initialize persistence
        let gameRepository = FileGameRepository(itemsRepository: itemsRepository)
        self.gameRepository = gameRepository

        // Initialize calendar service
        let calendarService = DefaultCalendarService()
        self.calendarService = calendarService

        // Initialize battle services
        let botAI = ElfRandomBotAI()
        self.botAI = botAI

        let snapshotCombatCalculator = ElfSnapshotCombatCalculator(
            damageService: damageService,
            dodgeService: dodgeService,
            critService: critService,
            debugLogger: debugBattleLogger
        )
        self.snapshotCombatCalculator = snapshotCombatCalculator

        self.battleLogger = ElfBattleLogger()

        let statisticsParser = ElfBattleStatisticsParser()
        self.statisticsParser = statisticsParser

        self.battleSimulationService = ElfBattleSimulationService(
            botAI: botAI,
            snapshotCombatCalculator: snapshotCombatCalculator,
            damageService: damageService,
            statisticsParser: statisticsParser
        )
        self.combatRoundExecutor = ElfCombatRoundExecutor(
            snapshotCombatCalculator: snapshotCombatCalculator,
            damageService: damageService
        )
        self.duelPairingService = RandomDuelPairingService()
        self.monsterRepository = ElfMonsterRepository()

        let fishRepository = ElfFishRepository()
        self.fishRepository = fishRepository

        let herbRepository = ElfHerbRepository()
        self.herbRepository = herbRepository

        let oreRepository = ElfOreRepository()
        self.oreRepository = oreRepository

        let materialRepository = ElfMaterialRepository(
            fishRepository: fishRepository,
            herbRepository: herbRepository,
            oreRepository: oreRepository
        )
        self.materialRepository = materialRepository

        // Hunt and drop services
        let huntService = ElfHuntService()
        self.huntService = huntService

        let dropService = DefaultDropService(
            materialRepository: materialRepository,
            itemsRepository: itemsRepository
        )
        self.dropService = dropService

        // Fishing service
        let fishingService = DefaultFishingService()
        self.fishingService = fishingService

        // Foraging service
        let foragingService = DefaultForagingService()
        self.foragingService = foragingService

        // Mining service
        let miningService = DefaultMiningService()
        self.miningService = miningService

        // Farm activity service (unified)
        self.farmActivityService = DefaultFarmActivityService(
            fishingService: fishingService,
            foragingService: foragingService,
            miningService: miningService,
            fishRepository: fishRepository,
            herbRepository: herbRepository,
            oreRepository: oreRepository
        )

        // Battle result calculation
        self.battleResultCalculator = DefaultBattleResultCalculator(
            huntService: huntService,
            dropService: dropService
        )

        // Game initialization service
        self.gameInitializationService = ElfGameInitializationService(
            houseService: self.houseService,
            elfInfoFactory: elfInfoFactory,
            calendarService: calendarService,
            gameRepository: gameRepository
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
            snapshotBuilder: self.snapshotBuilder,
            monsterRepository: self.monsterRepository
        )
    }

    @MainActor
    public func makeBattleFightViewModel(battle: Battle) -> BattleFightViewModel {
        return BattleFightViewModel(
            battle: battle,
            botAI: self.botAI,
            combatRoundExecutor: self.combatRoundExecutor,
            battleLogger: self.battleLogger,
            debugLogger: self.debugBattleLogger,
            duelPairingService: self.duelPairingService,
            gameService: self.activeGameService,
            monsterRepository: self.monsterRepository,
            battleResultCalculator: self.battleResultCalculator
        )
    }

    @MainActor
    public func makeAutoBattleViewModel(battle: Battle) -> AutoBattleViewModel {
        return AutoBattleViewModel(
            battle: battle,
            botAI: self.botAI,
            snapshotCombatCalculator: self.snapshotCombatCalculator,
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
    public func makeBattleResultViewModel(result: ManualBattleResult) -> BattleResultViewModel {
        return BattleResultViewModel(result: result)
    }

    @MainActor
    public func makeFishingResultViewModel(result: FishingResult) -> FishingResultViewModel {
        return FishingResultViewModel(result: result)
    }

    @MainActor
    public func makeForagingResultViewModel(result: ForagingResult) -> ForagingResultViewModel {
        return ForagingResultViewModel(result: result)
    }

    @MainActor
    public func makeMiningResultViewModel(result: MiningResult) -> MiningResultViewModel {
        return MiningResultViewModel(result: result)
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
            gameInitializationService: self.gameInitializationService
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
        // Clean up previous game session if exists
        activeGameService = nil

        let gameService = DefaultGameService(
            game: game,
            gameRepository: self.gameRepository,
            itemsRepository: self.itemsRepository,
            playTime: playTime
        )
        self.activeGameService = gameService
        return GameDayViewModel(gameService: gameService)
    }

    @MainActor
    public func makeHuntViewModel() -> HuntViewModel {
        guard let gameService = activeGameService else {
            fatalError("No active game session. HuntViewModel requires an active game.")
        }
        return HuntViewModel(
            gameService: gameService,
            monsterRepository: self.monsterRepository,
            materialRepository: self.materialRepository,
            itemsRepository: self.itemsRepository,
            snapshotBuilder: self.snapshotBuilder
        )
    }

    @MainActor
    public func makeFarmViewModel() -> FarmViewModel {
        guard let gameService = activeGameService else {
            fatalError("No active game session. FarmViewModel requires an active game.")
        }
        return FarmViewModel(gameService: gameService)
    }

    @MainActor
    public func makeFarmActivityViewModel(activity: FarmActivity) -> FarmActivityViewModel {
        guard let gameService = activeGameService else {
            fatalError("No active game session. FarmActivityViewModel requires an active game.")
        }
        return FarmActivityViewModel(
            activity: activity,
            gameService: gameService,
            farmActivityService: farmActivityService,
            monsterRepository: monsterRepository,
            snapshotBuilder: snapshotBuilder
        )
    }

    @MainActor
    public func makeCalendarViewModel(
        calendar: [GameDay],
        currentDayNumber: Int
    ) -> CalendarViewModel {
        return CalendarViewModel(
            calendar: calendar,
            currentDayNumber: currentDayNumber,
            daysPerIteration: self.calendarService.daysPerIteration
        )
    }

    @MainActor
    public func makeInventoryViewModel() -> InventoryViewModel {
        guard let gameService = activeGameService else {
            fatalError("No active game session. InventoryViewModel requires an active game.")
        }
        let equipmentService = DefaultEquipmentService(gameService: gameService)
        return InventoryViewModel(
            gameService: gameService,
            equipmentService: equipmentService,
            materialRepository: self.materialRepository
        )
    }

    // MARK: - Game Session Management

    /// Saves active game if exists (called on app background)
    @MainActor
    public func saveActiveGameIfNeeded() async {
        guard let gameService = activeGameService else { return }
        try? await gameService.saveGame()
    }

    // MARK: - Preview Support

    #if DEBUG
    /// Initialize a game session for SwiftUI previews without side effects
    @MainActor
    public func initializePreviewSession(game: Game) {
        activeGameService = DefaultGameService(
            game: game,
            gameRepository: self.gameRepository,
            itemsRepository: self.itemsRepository,
            playTime: 0
        )
    }
    #endif
}
