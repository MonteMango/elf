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
        // Hero-first roster comes from the session's single source of truth;
        // squadElves() already pins the hero first and silently drops allies
        // whose id no longer resolves.
        session.squadElves().map { memberDetail(for: $0, isHero: $0.id == session.heroId) }
    }

    // MARK: - Private

    private func memberDetail(for elf: ElfInfo, isHero: Bool) -> DungeonSquadMemberDetail {
        // HP/MP come from the session's `displayVitals(for:)`: live per-room
        // values once the squad has entered, full during the briefing. A
        // `hp <= 0` reading marks a downed member. No domain buffs yet — empty array.
        let vitals = session.displayVitals(for: elf)
        return DungeonSquadMemberDetail(
            id: elf.id.rawValue,
            name: elf.name,
            imageName: elf.imageName,
            level: progressionService.calculateLevel(currentExp: elf.currentExp),
            currentHP: vitals.hp,
            maxHP: Int(elf.maxHP),
            currentMP: vitals.mp,
            maxMP: Int(elf.maxMP),
            attributes: elf.totalAttributes,
            equippedItems: equippedSlotResolver.resolve(equipped: elf.equipped),
            activeBuffs: [],
            state: vitals.hp <= 0 ? .dead : .alive,
            isHero: isHero
        )
    }
}
