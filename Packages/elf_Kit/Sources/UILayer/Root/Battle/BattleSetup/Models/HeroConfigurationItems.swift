//
//  HeroConfigurationItems.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.06.25.
//

import Combine

public struct HeroConfigurationItems {
    public var helmet: ElfDefenseItem? = nil
    public var gloves: ElfDefenseItem? = nil
    public var shoes: ElfDefenseItem? = nil
    public var upperBody: ElfDefenseItem? = nil
    public var bottomBody: ElfDefenseItem? = nil
    public var shirt: ElfRobeItem? = nil

    public var ring: ElfJewelryItem? = nil
    public var necklace: ElfJewelryItem? = nil
    public var earrings: ElfJewelryItem? = nil

    public var handsUse: HoldInHandsWeapon = .noWeapon

    public init() {}
}
