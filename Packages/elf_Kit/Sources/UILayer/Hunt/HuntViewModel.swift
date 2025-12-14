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

    private let gameService: GameService
    private let monsterRepository: MonsterRepository
    private let materialRepository: MaterialRepository
    private let snapshotBuilder: CombatantSnapshotBuilder

    // MARK: - Constants

    /// Cost in action points to hunt
    public let huntCost: Int = 20

    // MARK: - Computed Properties

    public var currentActionPoints: Int {
        gameService.game.gameState.currentActionPoints
    }

    public var maxActionPoints: Int {
        gameService.game.gameState.maxActionPoints
    }

    public var canHunt: Bool {
        currentActionPoints >= huntCost
    }

    /// Player's current level (determines monster level)
    public var playerLevel: Int {
        Int(gameService.game.player.level)
    }

    /// Current world (for now, always upper world)
    /// TODO: Implement world progression logic
    public var currentWorld: WorldType {
        .upper
    }

    /// Available monsters for hunting based on current world and player level
    private var availableMonsters: [Monster] {
        // Monster level equals player level, capped at 3
        let monsterLevel = min(playerLevel, 3)
        return monsterRepository.getMonsters(world: currentWorld, level: monsterLevel)
    }

    /// Pre-converted display data for monsters (for View consumption)
    public var availableMonstersDisplayData: [MonsterDisplayData] {
        availableMonsters.map { createDisplayData(from: $0) }
    }

    // MARK: - Initialization

    public init(
        gameService: GameService,
        monsterRepository: MonsterRepository,
        materialRepository: MaterialRepository,
        snapshotBuilder: CombatantSnapshotBuilder
    ) {
        self.gameService = gameService
        self.monsterRepository = monsterRepository
        self.materialRepository = materialRepository
        self.snapshotBuilder = snapshotBuilder
    }

    // MARK: - Actions

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
        let selectedItems: [HeroItemType: UUID?] = player.equippedItemIds.mapValues { $0 }

        guard let playerSnapshot = await snapshotBuilder.buildSnapshot(
            name: player.name,
            imageName: player.imageName,
            level: player.level,
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
    private func createDisplayData(from monster: Monster) -> MonsterDisplayData {
        var dropImages: [String] = []

        // Weapon drops - use weapon.id as image name
        dropImages += monster.drops.weapons.map { $0.id }

        // Armor drops - use armor.id as image name
        dropImages += monster.drops.armor.map { $0.id }

        // Material drops - lookup via materialRepository
        for materialDrop in monster.drops.materials {
            if let material = materialRepository.getMaterial(id: materialDrop.id) {
                dropImages.append(material.imageName)
            }
        }

        // Remove duplicates while preserving order
        var seen = Set<String>()
        let uniqueImages = dropImages.filter { seen.insert($0).inserted }

        return MonsterDisplayData(
            id: monster.id,
            title: monster.title,
            imageName: monster.imageName,
            dropImageNames: uniqueImages
        )
    }
}
