//
//  HuntViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class HuntViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let session: GameSession
    private let monsterRepository: any MonsterRepository
    private let materialRepository: any Repository<Material>
    private let itemsRepository: any ItemsRepository
    private let snapshotBuilder: any CombatantSnapshotBuilder
    private let progressionService: any ProgressionService

    // MARK: - Constants / Local UI state

    /// Cost in action points to hunt
    public let huntCost: Int = 20
    public private(set) var isHunting: Bool = false

    // MARK: - Derived (computed reactively)

    public var canHunt: Bool {
        session.state.actionPoints.current >= huntCost && !isHunting
    }

    /// Pool of monsters for the player's current level.
    private var availableMonsters: [Monster] {
        let monsterLevel = min(progressionService.calculateLevel(currentExp: session.state.player.currentExp), 3)
        return monsterRepository.getMonsters(world: .upper, level: monsterLevel)
    }

    /// Display data for monsters — rebuilt automatically when player level changes.
    public var availableMonstersDisplayData: [MonsterDisplay] {
        availableMonsters.map { buildDisplayData(from: $0) }
    }

    // MARK: - Initialization

    public init(session: GameSession) {
        @Dependency(\.monsterRepository) var monsterRepository
        @Dependency(\.materialRepository) var materialRepository
        @Dependency(\.itemsRepository) var itemsRepository
        @Dependency(\.snapshotBuilder) var snapshotBuilder
        @Dependency(\.progressionService) var progressionService
        self.monsterRepository = monsterRepository
        self.materialRepository = materialRepository
        self.itemsRepository = itemsRepository
        self.snapshotBuilder = snapshotBuilder
        self.progressionService = progressionService

        self.session = session
    }

    // MARK: - Actions

    /// Starts a hunt: spends action points, selects random monster, returns Battle
    public func startHunt() -> Battle? {
        guard session.state.actionPoints.current >= huntCost, !isHunting else { return nil }
        isHunting = true
        defer { isHunting = false }

        guard let monster = availableMonsters.randomElement() else {
            return nil
        }

        session.spendActionPoints(huntCost)

        let player = session.state.player
        let playerSnapshot = snapshotBuilder.buildSnapshot(
            name: player.name,
            imageName: player.imageName,
            level: progressionService.calculateLevel(currentExp: player.currentExp),
            fightStyleAttributes: player.fightStyleAttributes,
            randomLevelAttributes: player.randomLevelAttributes,
            equipped: player.equipped
        )

        let monsterSnapshot = snapshotBuilder.buildSnapshot(from: monster)

        return Battle(
            leftTeam: [playerSnapshot],
            rightTeam: [monsterSnapshot]
        )
    }

    // MARK: - Private Helpers

    private func buildDisplayData(from monster: Monster) -> MonsterDisplay {
        var drops: [DropDisplay] = []

        for (idx, itemDrop) in monster.drops.weapons.enumerated() {
            if let uuid = UUID(uuidString: itemDrop.id),
               let item = itemsRepository.getHeroItem(uuid) {
                drops.append(DropDisplay(
                    id: "weapon-\(idx)",
                    imageName: itemDrop.id,
                    tier: Int(item.tier)
                ))
            }
        }

        for (idx, itemDrop) in monster.drops.armor.enumerated() {
            if let uuid = UUID(uuidString: itemDrop.id),
               let item = itemsRepository.getHeroItem(uuid) {
                drops.append(DropDisplay(
                    id: "armor-\(idx)",
                    imageName: itemDrop.id,
                    tier: Int(item.tier)
                ))
            }
        }

        for (idx, materialDrop) in monster.drops.materials.enumerated() {
            if let material = materialRepository.getById(id: materialDrop.id) {
                drops.append(DropDisplay(
                    id: "material-\(idx)",
                    imageName: material.imageName,
                    tier: 4
                ))
            }
        }

        return MonsterDisplay(
            id: monster.id,
            title: monster.title,
            imageName: monster.imageName,
            drops: drops
        )
    }
}
