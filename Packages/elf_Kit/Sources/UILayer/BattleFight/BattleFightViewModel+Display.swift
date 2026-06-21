//
//  BattleFightViewModel+Display.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - Display state (DTOs for views)

extension BattleFightViewModel {

    /// Render-ready state for the hero panel. Built per access; SwiftUI Equatable
    /// diff in the view ensures cheap re-renders.
    public var playerDisplay: HeroDisplayState {
        makeDisplay(forSource: playerSnapshot)
    }

    /// Render-ready state for the opponent panel. Uses `displayedBotSnapshot`
    /// as the visual anchor (kept stable for layout while hero waits) and
    /// overrides current vitals from the live `botSnapshot` when a duel pair
    /// is active.
    public var displayedBotDisplay: HeroDisplayState? {
        guard let displayed = displayedBotSnapshot else { return nil }
        return makeDisplay(forSource: displayed, liveVitals: botSnapshot)
    }

    /// Minimal cell descriptors for the duel columns. Three fields per cell
    /// — keeps SwiftUI diff cheap so per-round HP mutation on one combatant
    /// doesn't re-render every cell in the column.
    public var leftTeamCells: [CombatantCellState] {
        leftTeam.map(Self.makeCell)
    }

    public var rightTeamCells: [CombatantCellState] {
        rightTeam.map(Self.makeCell)
    }

    private static func makeCell(from snapshot: CombatantSnapshot) -> CombatantCellState {
        CombatantCellState(id: snapshot.id.rawValue, imageName: snapshot.imageName, isAlive: snapshot.isAlive)
    }

    /// Builds a `HeroDisplayState` from a source snapshot, optionally overriding
    /// the mutable vitals (currentHP/MP/EP, isAlive) from a separate live
    /// snapshot. When `liveVitals` is supplied, effective attributes also use
    /// the live source so a battle-buff-induced cap shift reflects in UI even
    /// when the layout anchor (`source`) is the frozen "displayed" snapshot.
    private func makeDisplay(
        forSource source: CombatantSnapshot,
        liveVitals: CombatantSnapshot? = nil
    ) -> HeroDisplayState {
        let effSource = liveVitals ?? source
        let effective = buffEffectsCalculator.effectiveAttributes(of: effSource)
        return HeroDisplayState(
            id: source.id.rawValue,
            name: source.name,
            level: source.level,
            imageName: source.imageName,
            currentHP: liveVitals?.currentHP ?? source.currentHP,
            maxHP: effective.hitPoints.intValue,
            currentMP: liveVitals?.currentMP ?? source.currentMP,
            maxMP: effective.manaPoints.intValue,
            currentEP: liveVitals?.currentEP ?? source.currentEP,
            maxEP: source.maxEP,
            strength: AttributeDisplay(base: effSource.baseStrength, effective: Int(effective.strength.value)),
            agility: AttributeDisplay(base: effSource.baseAgility, effective: Int(effective.agility.value)),
            power: AttributeDisplay(base: effSource.basePower, effective: Int(effective.power.value)),
            instinct: AttributeDisplay(base: effSource.baseInstinct, effective: Int(effective.instinct.value)),
            endurance: AttributeDisplay(base: effSource.baseEndurance, effective: Int(effective.endurance.value)),
            attackPointsCount: source.attackPoints,
            defensePointsCount: source.defensePoints,
            equippedItems: battle.equippedByCombatantId[source.id].map { equippedSlotResolver.resolve(equipped: $0) } ?? [:],
            buffBadges: makeBuffBadges(for: effSource),
            isAlive: liveVitals?.isAlive ?? source.isAlive
        )
    }

    /// Resolves `AppliedBuff` instances against the catalog into render-ready
    /// `BuffBadgeViewState` cells. View never reaches into `BuffsRepository`.
    private func makeBuffBadges(for snapshot: CombatantSnapshot) -> [BuffBadgeViewState] {
        let allBuffs = snapshot.globalBuffs + snapshot.battleBuffs
        return allBuffs.compactMap { applied in
            guard let buff = buffsRepository.getById(id: applied.buffId) else { return nil }
            let daysRemaining: Int?
            if buff.scope == .global,
               let duration = buff.durationDays,
               let appliedOnDay = applied.appliedOnDay,
               let currentDay = session?.state.currentDay.dayNumber {
                daysRemaining = max(0, duration - (currentDay - appliedOnDay))
            } else {
                daysRemaining = nil
            }
            return BuffBadgeViewState(
                id: applied.id.rawValue,
                title: buff.title,
                imageName: buff.imageName,
                polarity: buff.polarity,
                stacks: applied.stacks,
                daysRemaining: daysRemaining
            )
        }
    }
}
