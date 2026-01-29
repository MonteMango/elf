//
//  BattleRoundCalculatedPreResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public struct BattleRoundCalculatedPreResult: Sendable {
    // calculation based on hero power att and enemy instinct att. (ToDo: Need to implement this Service)
    public var leftCritChance: (chance: Double, multiplier: Double) // what is the current crit cahnce for this round on leftWeapon
    public var rightCritChance: (chance: Double, multiplier: Double)? // what is the current crit cahnce for this round on rightWeapon (if exists, it could be shield, it could be empty, it could be weapon in the left hand that uses 2 hands -> the nit nil)
    // crit multiplier could be from 1.0 till 2.5 this is multiplier for total damage calculation

    // calculation based on hero strength (Done by DamageService)
    public var leftStrengthAttackDamage: Int // calculation of additional damage from strength att
    public var rightStrengthAttackDamage: Int?

    // calculation based on ElfWeapon (min, max) damage and weapond enchantLevel (ToDo: Need to implement this in DamageService)
    public var leftWeaponAttackDamage: Int // calculation of weapon damage
    public var rightWeaponAttackDamage: Int?

    // detailed dodge calculation based on hero agility att and enemy instinct att (Done by DodgeService)
    public var dodgeDistribution: DodgeDistribution? // the probability distribution used for dodge
    public var dodgeStage1Roll: Int? // stage 1 roll (1-100) to select dodge chance
    public var selectedDodgeChance: Int16? // dodge chance selected from distribution
    public var dodgeStage2Roll: Int? // stage 2 roll (1-100) to check dodge success (nil for auto-fail/success)

    // the armor values for body parts (array always should contains some values, could be 0)
    public var armorValues: [BodyPart: Int] // used for calculation the final total damage
}
