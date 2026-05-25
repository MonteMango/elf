//
//  BattleFightDisplayModels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

// MARK: - HeroDisplayState

/// Render-ready state for `HeroDisplayView`. Built by `BattleFightViewModel`
/// per render: combat attributes are buff-folded (effective), equipment is
/// pre-resolved through `HeroEquippedSlotResolver`, and active buffs are
/// resolved against the catalog into `BuffBadgeViewState` cells.
///
/// View binds to this struct, not to `CombatantSnapshot`. Equatable so SwiftUI
/// can skip subtree re-renders when fields didn't actually change between two
/// VM-driven body re-evaluations.
public struct HeroDisplayState: Equatable, Sendable {

    // MARK: Identity
    public let id: UUID
    public let name: String
    public let level: Int
    public let imageName: String

    // MARK: Vitals (effective caps + current)
    public let currentHP: Int
    public let maxHP: Int
    public let currentMP: Int
    public let maxMP: Int
    public let currentEP: Int
    public let maxEP: Int

    // MARK: Combat attributes — base and effective
    public let strength: AttributeDisplay
    public let agility: AttributeDisplay
    public let power: AttributeDisplay
    public let instinct: AttributeDisplay
    public let endurance: AttributeDisplay

    // MARK: Per-round affordances
    public let attackPointsCount: Int
    public let defensePointsCount: Int

    // MARK: UI-resolved fields
    public let equippedItems: [HeroItemType: HeroEquippedSlot]
    public let buffBadges: [BuffBadgeViewState]
    public let isAlive: Bool

    public init(
        id: UUID,
        name: String,
        level: Int,
        imageName: String,
        currentHP: Int,
        maxHP: Int,
        currentMP: Int,
        maxMP: Int,
        currentEP: Int,
        maxEP: Int,
        strength: AttributeDisplay,
        agility: AttributeDisplay,
        power: AttributeDisplay,
        instinct: AttributeDisplay,
        endurance: AttributeDisplay,
        attackPointsCount: Int,
        defensePointsCount: Int,
        equippedItems: [HeroItemType: HeroEquippedSlot],
        buffBadges: [BuffBadgeViewState],
        isAlive: Bool
    ) {
        self.id = id
        self.name = name
        self.level = level
        self.imageName = imageName
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.currentMP = currentMP
        self.maxMP = maxMP
        self.currentEP = currentEP
        self.maxEP = maxEP
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
        self.endurance = endurance
        self.attackPointsCount = attackPointsCount
        self.defensePointsCount = defensePointsCount
        self.equippedItems = equippedItems
        self.buffBadges = buffBadges
        self.isAlive = isAlive
    }
}

// MARK: - AttributeDisplay

/// Paired base / effective attribute value. `effective == base` when no buff
/// is affecting that attribute. Views that want a "17 (base 25)" presentation
/// read both; views that only show the post-buff value read `effective`.
public struct AttributeDisplay: Equatable, Sendable {
    public let base: Int
    public let effective: Int

    public init(base: Int, effective: Int) {
        self.base = base
        self.effective = effective
    }
}

// MARK: - BuffBadgeViewState

/// Single render-ready buff cell. Resolves the catalog `Buff` for `AppliedBuff`
/// once in the VM so the view never reaches into `BuffsRepository`.
public struct BuffBadgeViewState: Identifiable, Equatable, Sendable {
    public let id: UUID              // AppliedBuff.id
    public let title: String         // catalog Buff.title
    public let imageName: String     // catalog Buff.imageName
    public let polarity: BuffPolarity
    public let stacks: Int
    /// Days remaining until expiry. `nil` for battle-scope buffs (they don't
    /// expire by day) and for global buffs whose catalog `durationDays == nil`.
    public let daysRemaining: Int?

    public init(
        id: UUID,
        title: String,
        imageName: String,
        polarity: BuffPolarity,
        stacks: Int,
        daysRemaining: Int?
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.polarity = polarity
        self.stacks = stacks
        self.daysRemaining = daysRemaining
    }
}

// MARK: - CombatantCellState

/// Minimal state for a combatant image cell in `DuelPairsColumnView`. Three
/// fields — keeps SwiftUI diff cheap so per-round HP mutation on one combatant
/// doesn't re-render every cell in the column.
public struct CombatantCellState: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let imageName: String
    public let isAlive: Bool

    public init(id: UUID, imageName: String, isAlive: Bool) {
        self.id = id
        self.imageName = imageName
        self.isAlive = isAlive
    }
}
