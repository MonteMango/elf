//
//  BattleRoundAction.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public struct BattleRoundAction: Hashable, Sendable {
    public var attackPoints: [BodyPart] // amount according to equipd items (1 weapon 1 point) (2 weapons 2 points). And selection from UI
    public var defensePoints: [BodyPart] // amount according to equipd items (Default 2 def points, when shield equiped +1). And selection from UI
}
