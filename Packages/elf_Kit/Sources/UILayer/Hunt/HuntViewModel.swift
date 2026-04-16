//
//  HuntViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

@MainActor
@Observable
public final class HuntViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService
    private let monsterRepository: any MonsterRepository
    private let materialRepository: any Repository<Material>
    private let itemsRepository: any ItemsRepository
    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let progressionService: any ProgressionService
    private let equipmentQueryService: any EquipmentQueryService

    // MARK: - Constants / Local UI state

    /// Cost in action points to hunt
    public let huntCost: Int = 20
    public private(set) var isHunting: Bool = false

    // MARK: - Game Session State (exposed for top bar / calendar nav)

    public var currentDay: GameDay { gameService.currentDay }
    public var upcomingDays: [GameDay] { gameService.upcomingDays }
    public var calendar: [GameDay] { gameService.calendar }
    public var actionPoints: ActionPoints { gameService.actionPoints }
    public var isLastDay: Bool { gameService.isLastDay }

    // MARK: - Derived (computed reactively)

    /// Pool of monsters for the player's current level.
    private var availableMonsters: [Monster] {
        let monsterLevel = min(progressionService.calculateLevel(currentExp: gameService.player.currentExp), 3)
        return monsterRepository.getMonsters(world: .upper, level: monsterLevel)
    }

    /// Display data for monsters — rebuilt automatically when player level changes.
    public var availableMonstersDisplayData: [MonsterDisplayData] {
        availableMonsters.map { buildDisplayData(from: $0) }
    }

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
    }

    // MARK: - Actions

    /// Advances to the next day and restores action points
    public func advanceToNextDay() async {
        gameService.advanceToNextDay()
        try? await gameService.saveGame()
    }

    /// Starts a hunt: spends action points, selects random monster, returns Battle
    public func startHunt() -> Battle? {
        guard gameService.actionPoints.current >= huntCost, !isHunting else { return nil }
        isHunting = true
        defer { isHunting = false }

        guard let monster = availableMonsters.randomElement() else {
            return nil
        }

        gameService.spendActionPoints(huntCost)

        let player = gameService.player.snapshot()
        let selectedItems: [HeroItemType: UUID?] = equipmentQueryService.equippedBaseItemIds(from: player.equipped).mapValues { $0 }

        guard let playerSnapshot = snapshotBuilder.buildSnapshot(
            name: player.name,
            imageName: player.imageName,
            level: progressionService.calculateLevel(currentExp: player.currentExp),
            fightStyleAttributes: player.fightStyleAttributes,
            randomLevelAttributes: player.randomLevelAttributes,
            selectedItems: selectedItems
        ) else {
            return nil
        }

        let monsterSnapshot = snapshotBuilder.buildSnapshot(from: monster)

        return Battle(
            leftTeam: [playerSnapshot],
            rightTeam: [monsterSnapshot]
        )
    }

    // MARK: - Private Helpers

    private func buildDisplayData(from monster: Monster) -> MonsterDisplayData {
        var drops: [DropDisplayData] = []

        for itemDrop in monster.drops.weapons {
            if let uuid = UUID(uuidString: itemDrop.id),
               let item = itemsRepository.getHeroItem(uuid) {
                drops.append(DropDisplayData(imageName: itemDrop.id, tier: Int(item.tier)))
            }
        }

        for itemDrop in monster.drops.armor {
            if let uuid = UUID(uuidString: itemDrop.id),
               let item = itemsRepository.getHeroItem(uuid) {
                drops.append(DropDisplayData(imageName: itemDrop.id, tier: Int(item.tier)))
            }
        }

        for materialDrop in monster.drops.materials {
            if let material = materialRepository.getById(id: materialDrop.id) {
                drops.append(DropDisplayData(imageName: material.imageName, tier: 4))
            }
        }

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
