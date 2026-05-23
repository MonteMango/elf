//
//  DungeonSquadViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Drives the Squad tab. Exposes the full per-elf detail (`DungeonSquadMemberDetail`)
/// used by the Squad-tab cells. Hero is always pinned first; ally rows follow
/// the order of `session.allyIds`.
@MainActor
@Observable
public final class DungeonSquadViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let session: DungeonSession
    private let progressionService: any ProgressionService
    private let equippedSlotResolver: any HeroEquippedSlotResolver

    // MARK: - Initialization

    public init(session: DungeonSession) {
        @Dependency(\.progressionService) var progressionService
        @Dependency(\.equippedSlotResolver) var equippedSlotResolver
        self.progressionService = progressionService
        self.equippedSlotResolver = equippedSlotResolver
        self.session = session
    }

    // MARK: - Derived

    public var squad: [DungeonSquadMemberDetail] {
        let player = session.gameStore.player
        var rows: [DungeonSquadMemberDetail] = [memberDetail(for: player, isHero: true)]

        let house = session.gameStore.houses[session.gameStore.playerHouseIndex]
        let elfById = Dictionary(uniqueKeysWithValues: house.members.map { ($0.id, $0) })
        for id in session.allyIds {
            guard let elf = elfById[id] else { continue }
            rows.append(memberDetail(for: elf, isHero: false))
        }
        return rows
    }

    // MARK: - Private

    private func memberDetail(for elf: ElfInfo, isHero: Bool) -> DungeonSquadMemberDetail {
        // MVP: no runtime HP/MP on ElfInfo yet — assume full reserves. No
        // domain buffs yet — empty array. State always alive.
        DungeonSquadMemberDetail(
            id: elf.id,
            name: elf.name,
            imageName: elf.imageName,
            level: progressionService.calculateLevel(currentExp: elf.currentExp),
            currentHP: Int(elf.maxHP),
            maxHP: Int(elf.maxHP),
            currentMP: Int(elf.maxMP),
            maxMP: Int(elf.maxMP),
            attributes: elf.totalAttributes,
            equippedItems: equippedSlotResolver.resolve(equipped: elf.equipped),
            activeBuffs: [],
            state: .alive,
            isHero: isHero
        )
    }
}
