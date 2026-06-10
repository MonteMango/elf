//
//  HeroSelection.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Hero's attack/defense selection for a single round, used by manual flows
/// (`BattleFightViewModel`). Auto/simulation flows pass `nil` to let the runner
/// fall back to bot AI for every pair.
public struct HeroSelection: Sendable {
    public let combatantId: UUID
    public let attackPoints: Set<BodyPart>
    public let defensePoints: Set<BodyPart>

    public init(
        combatantId: UUID,
        attackPoints: Set<BodyPart>,
        defensePoints: Set<BodyPart>
    ) {
        self.combatantId = combatantId
        self.attackPoints = attackPoints
        self.defensePoints = defensePoints
    }
}
