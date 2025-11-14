//
//  NewHeroConfiguration.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import SwiftUI

public struct NewHeroConfiguration {
    public var level: Int16 = 1
    public var fightStyle: FightStyle? = nil
    
    public var fightStyleAttributes: HeroAttributes? = nil
    public var levelRandomAttributes: HeroAttributes? = nil
}
