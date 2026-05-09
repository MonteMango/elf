//
//  DungeonOverviewViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Drives the Overview tab: title, expected monsters, possible drops, squad
/// preview, mini-map preview. All inputs come from the parent `DungeonSession`
/// (dungeon, gameStore, allyIds); aggregation services that map domain
/// types to display DTOs (monster lookup, drop tier resolution, level
/// calculation) come from `@Dependency`.
@MainActor
@Observable
public final class DungeonOverviewViewModel {

    // MARK: - Dependencies

    private let session: DungeonSession

    @ObservationIgnored
    @Dependency(\.monsterRepository) private var monsterRepository

    @ObservationIgnored
    @Dependency(\.itemsRepository) private var itemsRepository

    @ObservationIgnored
    @Dependency(\.progressionService) private var progressionService

    // MARK: - Initialization

    public init(session: DungeonSession) {
        self.session = session
    }

    // MARK: - Derived

    private var dungeon: Dungeon? { session.dungeon }

    public var header: DungeonHeaderDisplay {
        guard let dungeon else {
            return DungeonHeaderDisplay(title: "Unknown Dungeon", regionSubtitle: "", description: "")
        }
        return DungeonHeaderDisplay(
            title: dungeon.title,
            regionSubtitle: "\(formattedWorld(dungeon.world)) · \(dungeon.type.rawValue)",
            description: dungeon.description
        )
    }

    /// Three representative monsters: first mob of the entry combat room, the
    /// first mob of any miniBoss room, and the boss of the final boss room.
    /// If a category is missing, the slot is dropped — never padded with placeholders.
    public var expectedMonsters: [DungeonMonsterDisplay] {
        guard let dungeon else { return [] }

        var result: [DungeonMonsterDisplay] = []
        var seenMonsterIds: Set<UUID> = []

        let firstCombat = dungeon.rooms.first { room in
            if case .combat = room.kind { return true } else { return false }
        }
        if let monster = firstMonster(in: firstCombat?.kind), !seenMonsterIds.contains(monster.id) {
            result.append(displayData(monster))
            seenMonsterIds.insert(monster.id)
        }

        let firstMiniBoss = dungeon.rooms.first { room in
            if case .miniBoss = room.kind { return true } else { return false }
        }
        if let monster = firstMonster(in: firstMiniBoss?.kind), !seenMonsterIds.contains(monster.id) {
            result.append(displayData(monster))
            seenMonsterIds.insert(monster.id)
        }

        let bossRoom = dungeon.rooms.first { room in
            if case .boss = room.kind { return true } else { return false }
        }
        if let monster = firstMonster(in: bossRoom?.kind), !seenMonsterIds.contains(monster.id) {
            result.append(displayData(monster))
            seenMonsterIds.insert(monster.id)
        }

        return result
    }

    /// Up to 5 unique drops aggregated across every monster in the dungeon, in a
    /// stable order: weapons → armor → materials. Materials use a fixed tier of 4
    /// to colour their card consistently with the existing Hunt drop palette.
    public var possibleDrops: [DungeonDropDisplay] {
        guard let dungeon else { return [] }

        let allMonsters = dungeon.rooms.flatMap { $0.kind.monsters }
            .compactMap { monsterRepository.getById(id: $0.monsterId) }

        var seenIds = Set<String>()
        var drops: [DungeonDropDisplay] = []

        func appendIfNew(_ candidate: DungeonDropDisplay) {
            guard !seenIds.contains(candidate.id), drops.count < 5 else { return }
            seenIds.insert(candidate.id)
            drops.append(candidate)
        }

        for monster in allMonsters {
            for drop in monster.drops.weapons {
                guard let uuid = UUID(uuidString: drop.id),
                      let item = itemsRepository.getHeroItem(uuid) else { continue }
                appendIfNew(DungeonDropDisplay(id: drop.id, imageName: drop.id, tier: Int(item.tier)))
            }
        }
        for monster in allMonsters {
            for drop in monster.drops.armor {
                guard let uuid = UUID(uuidString: drop.id),
                      let item = itemsRepository.getHeroItem(uuid) else { continue }
                appendIfNew(DungeonDropDisplay(id: drop.id, imageName: drop.id, tier: Int(item.tier)))
            }
        }
        for monster in allMonsters {
            for drop in monster.drops.materials {
                appendIfNew(DungeonDropDisplay(
                    id: drop.id.uuidString,
                    imageName: drop.id.uuidString.lowercased(),
                    tier: 4
                ))
            }
        }

        return drops
    }

    /// Hero + selected allies. If an ally id no longer resolves (e.g. they died
    /// in a previous activity and were removed from the house), the row is
    /// silently dropped — the squad summary card handles fewer than 5 rows.
    public var squad: [DungeonSquadMemberDisplay] {
        let player = session.gameStore.player
        var rows: [DungeonSquadMemberDisplay] = [
            DungeonSquadMemberDisplay(
                id: player.id,
                name: player.name,
                imageName: player.imageName,
                level: progressionService.calculateLevel(currentExp: player.currentExp),
                currentHP: Int(player.maxHP),
                maxHP: Int(player.maxHP),
                isHero: true
            )
        ]

        let house = session.gameStore.houses[session.gameStore.playerHouseIndex]
        let elfById = Dictionary(uniqueKeysWithValues: house.members.map { ($0.id, $0) })
        for id in session.allyIds {
            guard let elf = elfById[id] else { continue }
            rows.append(DungeonSquadMemberDisplay(
                id: elf.id,
                name: elf.name,
                imageName: elf.imageName,
                level: progressionService.calculateLevel(currentExp: elf.currentExp),
                currentHP: Int(elf.maxHP),
                maxHP: Int(elf.maxHP),
                isHero: false
            ))
        }
        return rows
    }

    /// Linear walk of the room graph for the mini-map: entrance node followed by
    /// each room reached via `nextRoomIds[0]`. Cycle-safe — stops if a room is
    /// revisited or after `dungeon.rooms.count` hops.
    public var miniMapNodes: [DungeonRoomNodeDisplay] {
        guard let dungeon, let entryId = dungeon.entryRoomIds.first else { return [] }

        var nodes: [DungeonRoomNodeDisplay] = [
            DungeonRoomNodeDisplay(id: "entrance", kind: .entrance)
        ]

        var visited: Set<UUID> = []
        var currentId: UUID? = entryId
        while let id = currentId, !visited.contains(id), nodes.count <= dungeon.rooms.count {
            visited.insert(id)
            guard let room = dungeon.room(id: id) else { break }
            nodes.append(DungeonRoomNodeDisplay(id: id.uuidString, kind: nodeKind(for: room.kind)))
            currentId = room.nextRoomIds.first
        }
        return nodes
    }

    // MARK: - Private helpers

    private func firstMonster(in kind: DungeonRoomKind?) -> Monster? {
        guard let monsters = kind?.monsters, let ref = monsters.first else { return nil }
        return monsterRepository.getById(id: ref.monsterId)
    }

    private func displayData(_ monster: Monster) -> DungeonMonsterDisplay {
        DungeonMonsterDisplay(id: monster.id, title: monster.title, imageName: monster.imageName)
    }

    private func nodeKind(for kind: DungeonRoomKind) -> DungeonNodeKind {
        switch kind {
        case .combat: return .combat
        case .miniBoss: return .miniBoss
        case .event: return .event
        case .boss: return .boss
        }
    }

    private func formattedWorld(_ world: WorldType) -> String {
        switch world {
        case .upper: return "Upper World"
        case .middle: return "Middle World"
        case .lower: return "Lower World"
        }
    }
}
