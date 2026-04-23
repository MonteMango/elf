//
//  DependencyBootstrap.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import elf_Kit
import Foundation

/// One-shot app bootstrap: asynchronously loads game data, constructs every service
/// that depends on it, and registers them all via `prepareDependencies`.
///
/// Called exactly once at app launch from the splash-gate `.task {}` in `ElfApp`.
/// Must complete before any `@Dependency(\.xxx)` read — this is why `ElfApp` gates
/// the root UI behind a splash view.
@MainActor
public enum DependencyBootstrap {

    public static func run() async {
        let gameDataRepository = await DefaultGameDataRepository()

        // MARK: - Construction (dependency order: gameDataRepository first, then services that read from it)

        let attributeService = ElfAttributeService(itemsRepository: gameDataRepository.items)
        let armorService = ElfArmorService(itemsRepository: gameDataRepository.items)
        let damageService = ElfDamageService(
            itemsRepository: gameDataRepository.items,
            distributionStrategy: ElfStrengthDamageDistributionStrategy()
        )
        let weaponValidator = ElfWeaponValidator(itemsRepository: gameDataRepository.items)
        let snapshotBuilder = DefaultCombatantSnapshotBuilder(
            itemsRepository: gameDataRepository.items,
            armorService: armorService
        )

        let debugBattleLogger = ConsoleDebugBattleLogger(categories: [])
        let dodgeService = ElfDodgeService(distributionStrategy: ElfDodgeDistributionStrategy())
        let critService = ElfCritService(distributionStrategy: ElfCritDistributionStrategy())

        let snapshotCombatCalculator = ElfSnapshotCombatCalculator(
            damageService: damageService,
            dodgeService: dodgeService,
            critService: critService,
            debugLogger: debugBattleLogger
        )

        let progressionService = ElfProgressionService()
        let inventoryService = ElfInventoryService()
        let statisticsParser = ElfBattleStatisticsParser()

        let battleSimulationService = ElfBattleSimulationService(
            botAI: ElfRandomBotAI(),
            snapshotCombatCalculator: snapshotCombatCalculator,
            damageService: damageService,
            statisticsParser: statisticsParser
        )
        let combatRoundExecutor = ElfCombatRoundExecutor(
            snapshotCombatCalculator: snapshotCombatCalculator,
            damageService: damageService
        )

        let gameRepository = FileGameSaveStorage(
            itemsRepository: gameDataRepository.items,
            progressionService: progressionService,
            inventoryService: inventoryService
        )

        let huntService = ElfHuntService(itemsRepository: gameDataRepository.items)
        let dropService = DefaultDropService(materialRepository: gameDataRepository.materials)
        let gatheringEngine = DefaultGatheringEngine()
        let skillProgressCalculator = ElfSkillProgressCalculator()

        let fishingService = DefaultFishingService(
            gatheringEngine: gatheringEngine,
            skillProgressCalculator: skillProgressCalculator
        )
        let foragingService = DefaultForagingService(
            gatheringEngine: gatheringEngine,
            skillProgressCalculator: skillProgressCalculator
        )
        let miningService = DefaultMiningService(
            gatheringEngine: gatheringEngine,
            skillProgressCalculator: skillProgressCalculator
        )

        let farmActivityService = DefaultFarmActivityService(
            fishingService: fishingService,
            foragingService: foragingService,
            miningService: miningService,
            fishRepository: gameDataRepository.fish,
            herbRepository: gameDataRepository.herbs,
            oreRepository: gameDataRepository.ores,
            progressionService: progressionService
        )

        let battleResultCalculator = DefaultBattleResultCalculator(
            huntService: huntService,
            dropService: dropService,
            progressionService: progressionService
        )

        let elfInfoFactory = DefaultElfInfoFactory(
            attributeService: attributeService,
            itemsRepository: gameDataRepository.items,
            inventoryService: inventoryService
        )
        let houseService = DefaultHouseService(elfInfoFactory: elfInfoFactory)
        let calendarService = DefaultCalendarService()

        let gameInitializationService = ElfGameInitializationService(
            houseService: houseService,
            elfInfoFactory: elfInfoFactory,
            calendarService: calendarService,
            gameRepository: gameRepository
        )

        // MARK: - Registration

        prepareDependencies {
            $0.farmActivityService = farmActivityService
            $0.monsterRepository = gameDataRepository.monsters
            $0.snapshotBuilder = snapshotBuilder
            $0.itemsRepository = gameDataRepository.items
            $0.materialRepository = gameDataRepository.materials
            $0.recipeRepository = gameDataRepository.recipes
            $0.oreRepository = gameDataRepository.ores
            $0.questRepository = gameDataRepository.quests
            $0.herbRepository = gameDataRepository.herbs
            $0.fishRepository = gameDataRepository.fish
            $0.attributeService = attributeService
            $0.armorService = armorService
            $0.damageService = damageService
            $0.weaponValidator = weaponValidator
            $0.snapshotCombatCalculator = snapshotCombatCalculator
            $0.combatRoundExecutor = combatRoundExecutor
            $0.battleSimulationService = battleSimulationService
            $0.battleResultCalculator = battleResultCalculator
            $0.gameInitializationService = gameInitializationService
            $0.gameRepository = gameRepository
        }
    }
}
