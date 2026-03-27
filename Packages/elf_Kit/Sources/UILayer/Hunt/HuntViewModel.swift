//
//  HuntViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

@Observable
@MainActor
public final class HuntViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService
    private let monsterRepository: any MonsterRepository
    private let materialRepository: any Repository<Material>
    private let itemsRepository: any ItemsRepository
    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let progressionService: any ProgressionService
    private let equipmentQueryService: any EquipmentQueryService

    // MARK: - Constants

    /// Cost in action points to hunt
    public let huntCost: Int = 20

    // MARK: - Game State

    private var game: Game

    // MARK: - Computed Properties

    public var currentActionPoints: Int {
        game.gameState.currentActionPoints
    }

    public var maxActionPoints: Int {
        game.gameState.maxActionPoints
    }

    public var canHunt: Bool {
        currentActionPoints >= huntCost
    }

    public var isLastDay: Bool {
        game.gameState.isLastDay
    }

    // MARK: - Calendar Properties

    /// Current game day
    public var currentDay: GameDay {
        game.gameState.currentDay
    }

    /// Next upcoming days
    public var upcomingDays: [GameDay] {
        game.gameState.upcomingDays
    }

    /// Full game calendar
    public var calendar: [GameDay] {
        game.gameState.calendar
    }

    /// Player's current level (determines monster level)
    public func playerLevel() async -> Int {
        await progressionService.calculateLevel(currentExp: gameService.game.player.currentExp)
    }

    /// Current world (for now, always upper world)
    /// TODO: Implement world progression logic
    public var currentWorld: WorldType {
        .upper
    }

    /// Pre-converted display data for monsters (for View consumption)
    public var availableMonstersDisplayData: [MonsterDisplayData] = []

    /// Cached available monsters for the current world/level
    private var availableMonsters: [Monster] = []

    // MARK: - Initialization

    public init(
        gameService: any GameService,
        monsterRepository: any MonsterRepository,
        materialRepository: any Repository<Material>,
        itemsRepository: any ItemsRepository,
        snapshotBuilder: any CombatantSnapshotBuilder,
        progressionService: any ProgressionService,
        equipmentQueryService: any EquipmentQueryService
    ) {
        self.gameService = gameService
        self.monsterRepository = monsterRepository
        self.materialRepository = materialRepository
        self.itemsRepository = itemsRepository
        self.snapshotBuilder = snapshotBuilder
        self.progressionService = progressionService
        self.equipmentQueryService = equipmentQueryService
        self.game = gameService.game
    }

    // MARK: - Game State Observation

    public func observeGameState() async {
        for await game in gameService.gameUpdates() {
            self.game = game
        }
    }

    // MARK: - Data Loading

    /// Loads available monsters and builds display data.
    /// Call from View's .task {} modifier.
    public func loadMonsters() async {
        let monsterLevel = min(await playerLevel(), 3)
        availableMonsters = await monsterRepository.getMonsters(world: currentWorld, level: monsterLevel)

        var displayData: [MonsterDisplayData] = []
        for monster in availableMonsters {
            let data = await createDisplayData(from: monster)
            displayData.append(data)
        }
        availableMonstersDisplayData = displayData
    }

    // MARK: - Actions

    /// Advances to the next day and restores action points
    public func advanceToNextDay() {
        gameService.advanceToNextDay()
        Task {
            try? await gameService.saveGame()
        }
    }

    /// Starts a hunt: spends action points, selects random monster, returns Battle
    /// - Returns: Battle instance or nil if hunt cannot start
    public func startHunt() async -> Battle? {
        guard canHunt else { return nil }

        // 1. Select random monster from available monsters (before spending AP)
        guard let monster = availableMonsters.randomElement() else {
            return nil
        }

        // 2. Spend action points (only after confirming monster exists)
        gameService.spendActionPoints(huntCost)

        // 3. Build player snapshot from ElfInfo
        let player = gameService.game.player
        let selectedItems: [HeroItemType: UUID?] = await equipmentQueryService.equippedBaseItemIds(from: player.equipped).mapValues { $0 }

        guard let playerSnapshot = await snapshotBuilder.buildSnapshot(
            name: player.name,
            imageName: player.imageName,
            level: await progressionService.calculateLevel(currentExp: player.currentExp),
            fightStyleAttributes: player.fightStyleAttributes,
            randomLevelAttributes: player.randomLevelAttributes,
            selectedItems: selectedItems
        ) else {
            return nil
        }

        // 4. Build monster snapshot
        let monsterSnapshot = snapshotBuilder.buildSnapshot(from: monster)

        // 5. Create and return Battle
        return Battle(
            leftTeam: [playerSnapshot],
            rightTeam: [monsterSnapshot]
        )
    }

    // MARK: - Private Helpers

    /// Converts Monster model to display data for the View
    private func createDisplayData(from monster: Monster) async -> MonsterDisplayData {
        var drops: [DropDisplayData] = []

        // Weapon drops - lookup item for tier
        for itemDrop in monster.drops.weapons {
            if let uuid = UUID(uuidString: itemDrop.id),
               let item = await itemsRepository.getHeroItem(uuid) {
                drops.append(DropDisplayData(
                    imageName: itemDrop.id,
                    tier: Int(item.tier)
                ))
            }
        }

        // Armor drops - lookup item for tier
        for itemDrop in monster.drops.armor {
            if let uuid = UUID(uuidString: itemDrop.id),
               let item = await itemsRepository.getHeroItem(uuid) {
                drops.append(DropDisplayData(
                    imageName: itemDrop.id,
                    tier: Int(item.tier)
                ))
            }
        }

        // Material drops - default tier 4 (common)
        for materialDrop in monster.drops.materials {
            if let material = await materialRepository.getById(id: materialDrop.id) {
                drops.append(DropDisplayData(
                    imageName: material.imageName,
                    tier: 4
                ))
            }
        }

        // Remove duplicates while preserving order (by imageName)
        var seen = Set<String>()
        let uniqueDrops = drops.filter { seen.insert($0.imageName).inserted }

        return MonsterDisplayData(
            id: monster.id,
            title: monster.title,
            imageName: monster.imageName,
            drops: uniqueDrops
        )
    }
}
