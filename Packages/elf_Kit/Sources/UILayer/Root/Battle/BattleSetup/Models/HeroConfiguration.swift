//
//  HeroConfiguration.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 31.10.24.
//

import Combine
import Foundation

public final class HeroConfiguration: ObservableObject {
    
    @Published public var level: Int16 = 1
    
    @Published public var fightStyle: FightStyle? = nil
    
    @Published public var fightStyleAttributes: HeroAttributes? = nil
    @Published public var levelRandomAttributes: HeroAttributes? = nil
    @Published public var itemsAttributes: HeroAttributes? = nil
    @Published public var itemsArmor: [BodyPart: Int16] = [
        .head: 0,
        .leftHand: 0,
        .body: 0,
        .rightHand: 0,
        .legs: 0
    ]
    
    @Published public var items: HeroConfigurationItems = HeroConfigurationItems()
    @Published public var minMaxStrengthDamage: (minDmg: Int16, maxDmg: Int16)? = nil
}
