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
        materialRepository: MaterialRepository
    ) {
        self.gameService = gameService
        self.monsterRepository = monsterRepository
        self.materialRepository = materialRepository
    }

    // MARK: - Actions

    /// Called when Hunt button is tapped
    /// For now, this is UI-only - actual hunting logic will be implemented later
    public func onHuntTapped() {
        guard canHunt else { return }
        // TODO: Implement hunting logic
        // 1. Spend action points
        // 2. Select random monster
        // 3. Start battle or calculate result
        print("Hunt tapped! Available monsters: \(availableMonsters.count)")
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
