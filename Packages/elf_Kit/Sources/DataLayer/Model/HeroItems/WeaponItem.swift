//
//  WeaponItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.11.24.
//

import Foundation

public class WeaponItem: Item {
    public let id: UUID
    public let title: String
    public let tier: Int16
    public let isUnique: Bool?
    
    public let minimumAttackPoint: Int16
    public let maximumAttackPoint: Int16
    
    public let strength: Int16?
    public let agility: Int16?
    public let power: Int16?
    public let instinct: Int16?
    
    public let hitPoints: Int16?
    public let manaPoints: Int16?
    
    public let weaponSpecialAbility: WeaponSpecialAbility?
    
    public let handUse: WeaponHandUse
}
