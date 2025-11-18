//
//  Battle.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public struct Battle {
    public let id: UUID

    // when battle starts there are 2 teams. The values passed as struct and never changed. These are initial information about ElfHero
    public let leftTeam: [ElfHero]
    public let rightTeam: [ElfHero]

    public var currentRound: Int {
        // based on roundLog.count + 1
        return roundLog.count + 1
    }

    // history of rounds
    public var roundLog: [RoundLog] = []

    public init(id: UUID = UUID(), leftTeam: [ElfHero], rightTeam: [ElfHero]) {
        self.id = id
        self.leftTeam = leftTeam
        self.rightTeam = rightTeam
    }
}

public struct RoundLog {
    public let roundNumber: Int //current round number
    
    public var action: [ElfHero: BattleRoundAction] // which actions were made (what attacked, what defended) For each elfHero
    public var duels: [(ElfHero, ElfHero)] // the opponents for current round (could be different in next round)
    public var calculatedPreResults: [ElfHero: BattleRoundCalculatedPreResult] // pre calculation for calculation results
    public var results: [ElfHero: BattleRoundResult] // the result of the round
}

public struct BattleRoundAction: Hashable {
    public var attackPoints: [BodyPart] // amount according to equipd items (1 weapon 1 point) (2 weapons 2 points). And selection from UI
    public var defensePoints: [BodyPart] // amount according to equipd items (Default 2 def points, when shield equiped +1). And selection from UI
}

public struct BattleRoundCalculatedPreResult {
    // calculation based on hero power att and enemy instinct att. (ToDo: Need to implement this Service)
    public var leftCritChance: (chance: Double, multiplier: Double) // what is the current crit cahnce for this round on leftWeapon
    public var rightCritChance: (chance: Double, multiplier: Double)? // what is the current crit cahnce for this round on rightWeapon (if exists, it could be shield, it could be empty, it could be weapon in the left hand that uses 2 hands -> the nit nil)
    // crit multiplier could be from 1.0 till 2.5 this is multiplier for total damage calculation
    
    // calculation based on hero strength (Done by DamageService)
    public var leftStrengthAttackDamage: Int // calculation of additional damage from strength att
    public var rightStrengthAttackDamage: Int?
    
    // calculation based on ElfWeapon (min, max) damage and weapond enchantLevel (ToDo: Need to implement this in DamageService)
    public var leftWeaponAttackDamage: Int // calculation of weapon damage
    public var rightWeapondAttackDamage: Int?
    
    // calculation based on hero agility att and enemy instinct att. (ToDo: Need to implement this Service)
    public var dodgeChance: Double // chance to dodge all attacks
    
    // the armor values for body parts (array always should contains some values, could be 0)
    public var armorValues: [BodyPart: Int] // used for calculation the final total damage
}

public struct BattleRoundResult {
    
    // Here is formula for total damage totalDamage = ( weaponAttackDamage + strengthAttackDamage - enemyArmor ) * critMultiplier
    // if enemy dodged that no damage at all
    
    public var pointStatus: [BodyPart: PointStatus] // the status of each point (will be displayed in UI) and used for calculation
    
    public var oldHP: Int
    public var newHP: Int {
        // base on demage from pointsStatus
        return 1
    }
}

public enum PointStatus: Sendable {
    case blocked
    case hit(damage: Int) // here is totalDamage
    case critHit(damage: Int) // here is totalDamage (when crit happaned)
    case dodged
    case nothing
}
