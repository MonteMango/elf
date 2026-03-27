//
//  ElfGameContainer.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import Foundation

/// Contains all game services, repositories, and ViewModel factories.
/// Created asynchronously — loads JSON data on the cooperative thread pool.
@Observable
public final class ElfGameContainer {

    // MARK: - Long-lived dependencies (concrete types for static dispatch)

    public let attributeService: ElfAttributeService
    public let armorService: ElfArmorService
    public let damageService: ElfDamageService
    public let weaponValidator: ElfWeaponValidator
    public let snapshotBuilder: DefaultCombatantSnapshotBuilder
    public let fightStyleDescriptionService: DefaultFightStyleDescriptionService
    public let nameSuggestionService: DefaultCharacterNameSuggestionService
    public let houseService: DefaultHouseService
    public let gameRepository: FileGameSaveStorage
    public let calendarService: DefaultCalendarService

    // Battle services (concrete types for static dispatch)
    public let botAI: ElfRandomBotAI
    public let snapshotCombatCalculator: ElfSnapshotCombatCalculator
    public let battleLogger: ElfBattleLogger
    public let debugBattleLogger: ConsoleDebugBattleLogger
    public let statisticsParser: ElfBattleStatisticsParser
    public let battleSimulationService: ElfBattleSimulationService
    public let combatRoundExecutor: ElfCombatRoundExecutor
    public let duelPairingService: RandomDuelPairingService
    public let gameDataRepository: DefaultGameDataRepository

    // Farm activity service (unified for all farm activities)
    public let farmActivityService: DefaultFarmActivityService

    // Battle result calculation
    public let battleResultCalculator: DefaultBattleResultCalculator

    // Game initialization
    public let gameInitializationService: ElfGameInitializationService

    // Business logic services (extracted from models)
    public let progressionService: ElfProgressionService
    public let inventoryService: ElfInventoryService
    public let statisticsAggregator: ElfBattleStatisticsAggregator
    public let skillProgressCalculator: ElfSkillProgressCalculator
    public let equipmentQueryService: ElfEquipmentQueryService

    // MARK: - Game Session State

    /// Currently active game service (nil when not in game)
    @ObservationIgnored
    public private(set) var activeGameService: DefaultGameService?

    // MARK: - Initialization

    public init() async {
        let gameDataRepository = await DefaultGameDataRepository()
        self.gameDataRepository = gameDataRepository

        let attributeService = ElfAttributeService(itemsRepository: gameDataRepository.items)
        let inventoryService = ElfInventoryService()
        let elfInfoFactory = DefaultElfInfoFactory(
            attributeService: attributeService,
            itemsRepository: gameDataRepository.items,
            inventoryService: inventoryService
        )
        let armorService = ElfArmorService(itemsRepository: gameDataRepository.items)

        self.attributeService = attributeService
        self.armorService = armorService

        // Debug logger with empty categories = no logging output
        let debugBattleLogger = ConsoleDebugBattleLogger(categories: [])
        self.debugBattleLogger = debugBattleLogger

        let damageService = ElfDamageService(itemsRepository: gameDataRepository.items)
        self.damageService = damageService

        // Initialize dodge service with distribution strategy
        let dodgeDistributionStrategy = ElfDodgeDistributionStrategy()
        let dodgeService = ElfDodgeService(distributionStrategy: dodgeDistributionStrategy)

        // Initialize crit service with distribution strategy
        let critDistributionStrategy = ElfCritDistributionStrategy()
        let critService = ElfCritService(distributionStrategy: critDistributionStrategy)

        self.weaponValidator = ElfWeaponValidator(itemsRepository: gameDataRepository.items)
        self.snapshotBuilder = DefaultCombatantSnapshotBuilder(
            itemsRepository: gameDataRepository.items,
            armorService: armorService
        )

        // Initialize character creation services
        self.fightStyleDescriptionService = DefaultFightStyleDescriptionService()
        self.nameSuggestionService = DefaultCharacterNameSuggestionService()

        // Business logic services (created early for other services)
        let progressionService = ElfProgressionService()
        self.progressionService = progressionService
        self.inventoryService = inventoryService
        self.statisticsAggregator = ElfBattleStatisticsAggregator()
        self.skillProgressCalculator = ElfSkillProgressCalculator()
        self.equipmentQueryService = ElfEquipmentQueryService()

        // House service (depends on elfInfoFactory)
        self.houseService = DefaultHouseService(
            elfInfoFactory: elfInfoFactory
        )

        // Initialize persistence
        let gameRepository = FileGameSaveStorage(
            itemsRepository: gameDataRepository.items,
            progressionService: progressionService,
            inventoryService: inventoryService
        )
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

        let huntService = ElfHuntService()

        let dropService = DefaultDropService(
            materialRepository: gameDataRepository.materials,
            itemsRepository: gameDataRepository.items
        )

        let gatheringEngine = DefaultGatheringEngine()

        let fishingService = DefaultFishingService(
            gatheringEngine: gatheringEngine,
            skillProgressCalculator: self.skillProgressCalculator
        )

        let foragingService = DefaultForagingService(
            gatheringEngine: gatheringEngine,
            skillProgressCalculator: self.skillProgressCalculator
        )

        let miningService = DefaultMiningService(
            gatheringEngine: gatheringEngine,
            skillProgressCalculator: self.skillProgressCalculator
        )

        // Farm activity service (unified)
        self.farmActivityService = DefaultFarmActivityService(
            fishingService: fishingService,
            foragingService: foragingService,
            miningService: miningService,
            fishRepository: gameDataRepository.fish,
            herbRepository: gameDataRepository.herbs,
            oreRepository: gameDataRepository.ores,
            progressionService: progressionService
        )

        // Battle result calculation
        self.battleResultCalculator = DefaultBattleResultCalculator(
            huntService: huntService,
            dropService: dropService,
            progressionService: progressionService
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
            itemsRepository: self.gameDataRepository.items,
            attributeService: self.attributeService,
            armorService: self.armorService,
            damageService: self.damageService,
            weaponValidator: self.weaponValidator,
            snapshotBuilder: self.snapshotBuilder,
            monsterRepository: self.gameDataRepository.monsters
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
            monsterRepository: self.gameDataRepository.monsters,
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
            battleSimulationService: self.battleSimulationService,
            statisticsAggregator: self.statisticsAggregator
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
            itemsRepository: self.gameDataRepository.items
        )
    }

    @MainActor
    public func makeGameDayViewModel(game: Game, playTime: TimeInterval = 0) -> GameDayViewModel {
        // Clean up previous game session if exists
        activeGameService = nil

        let gameService = DefaultGameService(
            game: game,
            gameRepository: self.gameRepository,
            itemsRepository: self.gameDataRepository.items,
            inventoryService: self.inventoryService,
            playTime: playTime
        )
        self.activeGameService = gameService
        return GameDayViewModel(
            gameService: gameService,
            progressionService: self.progressionService,
            equipmentQueryService: self.equipmentQueryService
        )
    }

    @MainActor
    public func makeHuntViewModel() -> HuntViewModel {
        guard let gameService = activeGameService else {
            fatalError("No active game session. HuntViewModel requires an active game.")
        }
        return HuntViewModel(
            gameService: gameService,
            monsterRepository: self.gameDataRepository.monsters,
            materialRepository: self.gameDataRepository.materials,
            itemsRepository: self.gameDataRepository.items,
            snapshotBuilder: self.snapshotBuilder,
            progressionService: self.progressionService,
            equipmentQueryService: self.equipmentQueryService
        )
    }

    @MainActor
    public func makeFarmViewModel() -> FarmViewModel {
        guard let gameService = activeGameService else {
            fatalError("No active game session. FarmViewModel requires an active game.")
        }
        return FarmViewModel(
            gameService: gameService,
            progressionService: self.progressionService
        )
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
            progressionService: self.progressionService,
            equipmentQueryService: self.equipmentQueryService,
            monsterRepository: self.gameDataRepository.monsters,
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
    public func makeCraftViewModel() -> CraftViewModel {
        guard let gameService = activeGameService else {
            fatalError("No active game session. CraftViewModel requires an active game.")
        }
        let craftService = DefaultCraftService()
        return CraftViewModel(
            gameService: gameService,
            recipeRepository: self.gameDataRepository.recipes,
            itemsRepository: self.gameDataRepository.items,
            materialRepository: self.gameDataRepository.materials,
            craftService: craftService,
            inventoryService: self.inventoryService
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
            materialRepository: self.gameDataRepository.materials,
            equipmentQueryService: self.equipmentQueryService
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
            itemsRepository: self.gameDataRepository.items,
            inventoryService: self.inventoryService,
            playTime: 0
        )
    }
    #endif
}
