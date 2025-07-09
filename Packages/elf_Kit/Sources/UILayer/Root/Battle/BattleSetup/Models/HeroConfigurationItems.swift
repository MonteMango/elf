//
//  HeroConfigurationItems.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.06.25.
//

import Combine

public final class HeroConfigurationItems {
    @Published public var helmet: ElfDefenseItem? = nil
    @Published public var gloves: ElfDefenseItem? = nil
    @Published public var shoes: ElfDefenseItem? = nil
    @Published public var upperBody: ElfDefenseItem? = nil
    @Published public var bottomBody: ElfDefenseItem? = nil
    @Published public var shirt: ElfRobeItem? = nil
    
    @Published public var ring: ElfJewelryItem? = nil
    @Published public var necklace: ElfJewelryItem? = nil
    @Published public var earrings: ElfJewelryItem? = nil
    
    @Published public var handsUse: HoldInHandsWeapon = .noWeapon
}
