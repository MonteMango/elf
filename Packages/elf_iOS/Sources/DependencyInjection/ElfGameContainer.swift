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
@MainActor
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
    public let debugGameLogger: ConsoleDebugGameLogger
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
    public let craftService: CraftService
    public let statisticsAggregator: ElfBattleStatisticsAggregator
    public let skillProgressCalculator: ElfSkillProgressCalculator
    public let equipmentQueryService: ElfEquipmentQueryService

    // MARK: - Game Session State

    /// Non-optional owner of the active game session (game service + day state VM).
    /// Created in `startGameSession(game:playTime:)`, released in `endGameSession()`.
    public private(set) var sessionModel: GameSessionModel?

    /// Currently active game service (nil when not in game).
    /// Forwards to `sessionModel.gameService` and is kept for the screens/factories
    /// that have not yet been migrated to read from `sessionModel` directly.
    public var activeGameService: DefaultGameService? {
        sessionModel?.gameService as? DefaultGameService
    }

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

        // Debug loggers with empty categories = no logging output
        let debugBattleLogger = ConsoleDebugBattleLogger(categories: [])
        self.debugBattleLogger = debugBattleLogger

        let debugGameLogger = ConsoleDebugGameLogger(categories: [.playerInfo, .gameState, .inventory, .equipment, .houses])
        self.debugGameLogger = debugGameLogger

        let damageService = ElfDamageService(
            itemsRepository: gameDataRepository.items,
            distributionStrategy: ElfStrengthDamageDistributionStrategy()
        )
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
        self.craftService = DefaultCraftService()
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

        let huntService = ElfHuntService(itemsRepository: gameDataRepository.items)

        let dropService = DefaultDropService(
            materialRepository: gameDataRepository.materials
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

    public func makeAutoBattleViewModel(battle: Battle) -> AutoBattleViewModel {
        return AutoBattleViewModel(
            battle: battle,
            botAI: self.botAI,
            snapshotCombatCalculator: self.snapshotCombatCalculator,
            damageService: self.damageService,
            statisticsParser: self.statisticsParser
        )
    }

    public func makeMultiBattleViewModel(battle: Battle) -> MultiBattleViewModel {
        return MultiBattleViewModel(
            battle: battle,
            battleSimulationService: self.battleSimulationService,
            statisticsAggregator: self.statisticsAggregator,
            totalBattles: PerfTestConfig.multiBattleCount
        )
    }

    public func makeBattleResultViewModel(result: ManualBattleResult) -> BattleResultViewModel {
        return BattleResultViewModel(result: result)
    }

    public func makeFishingResultViewModel(result: FishingResult) -> FishingResultViewModel {
        return FishingResultViewModel(result: result)
    }

    public func makeForagingResultViewModel(result: ForagingResult) -> ForagingResultViewModel {
        return ForagingResultViewModel(result: result)
    }

    public func makeMiningResultViewModel(result: MiningResult) -> MiningResultViewModel {
        return MiningResultViewModel(result: result)
    }

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


    public func makeInventoryViewModel() -> InventoryViewModel {
        guard let gameService = activeGameService else {
            fatalError("No active game session. InventoryViewModel requires an active game.")
        }
        let equipmentService = DefaultEquipmentService(
            gameService: gameService,
            itemsRepository: self.gameDataRepository.items
        )
        return InventoryViewModel(
            gameService: gameService,
            equipmentService: equipmentService,
            materialRepository: self.gameDataRepository.materials,
            fishRepository: self.gameDataRepository.fish,
            herbRepository: self.gameDataRepository.herbs,
            oreRepository: self.gameDataRepository.ores,
            equipmentQueryService: self.equipmentQueryService
        )
    }

    // MARK: - Game Session Management

    /// Starts (or replaces) the active game session. Must be called before navigating
    /// to `.gameSession` so that `DefaultGameService` is available in the environment.
    public func startGameSession(game: Game, playTime: TimeInterval = 0) {
        let service = DefaultGameService(
            game: game,
            gameRepository: self.gameRepository,
            inventoryService: self.inventoryService,
            craftService: self.craftService,
            debugGameLogger: self.debugGameLogger,
            playTime: playTime
        )
        sessionModel = GameSessionModel(gameService: service)
    }

    /// Ends the active game session and releases the `DefaultGameService`.
    /// Safe to call at any time: screens access the service only through their
    /// ViewModel, which retains a strong reference until the view unmounts.
    public func endGameSession() {
        sessionModel = nil
    }

    /// Saves active game if exists (called on app background)
    public func saveActiveGameIfNeeded() async {
        guard let gameService = sessionModel?.gameService else { return }
        try? await gameService.saveGame()
    }

    // MARK: - Preview Support

    #if DEBUG
    /// Initialize a game session for SwiftUI previews without side effects
    public func initializePreviewSession(game: Game) {
        let service = DefaultGameService(
            game: game,
            gameRepository: self.gameRepository,
            inventoryService: self.inventoryService,
            craftService: self.craftService,
            debugGameLogger: self.debugGameLogger,
            playTime: 0
        )
        sessionModel = GameSessionModel(gameService: service)
    }
    #endif

    // MARK: - Required Accessors

    /// Returns the shared `GameDayStateViewModel`. Must only be called while a
    /// game session is active.
    public func requireGameDayStateViewModel() -> GameDayStateViewModel {
        guard let viewModel = sessionModel?.dayState else {
            fatalError("No active game session. GameDayStateViewModel requires an active game.")
        }
        return viewModel
    }
}
