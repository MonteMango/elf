//
//  HeroAttributes.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 31.10.24.
//

public struct HeroAttributes {
    public var hitPoints: Int16 = 0
    public var manaPoints: Int16 = 0
    public var agility: Int16 = 0
    public var strength: Int16 = 0
    public var power: Int16 = 0
    public var instinct: Int16 = 0

    public init(
        hitPoints: Int16 = 0,
        manaPoints: Int16 = 0,
        agility: Int16 = 0,
        strength: Int16 = 0,
        power: Int16 = 0,
        instinct: Int16 = 0
    ) {
        self.hitPoints = hitPoints
        self.manaPoints = manaPoints
        self.agility = agility
        self.strength = strength
        self.power = power
        self.instinct = instinct
    }
}
