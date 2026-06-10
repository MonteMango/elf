//
//  BattleRoundResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public struct BattleRoundResult: Sendable {

    // Here is formula for total damage totalDamage = ( weaponAttackDamage + strengthAttackDamage - enemyArmor ) * critMultiplier
    // if enemy dodged that no damage at all

    public var pointStatus: [BodyPart: PointStatus] // the status of each point (will be displayed in UI) and used for calculation
}
