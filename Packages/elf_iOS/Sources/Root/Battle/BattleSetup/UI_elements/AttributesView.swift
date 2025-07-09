//
//  AttributesView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 07.11.24.
//

import elf_Kit

internal protocol AttributesView {
    func updateAttributes(fightStyleAttributes: HeroAttributes?, levelRandomAttributes: HeroAttributes?, itemsAttributes: HeroAttributes?)
    func updateDamageAttributes(primaryMinDmg: Int16, primaryMaxDmg: Int16, secondaryMinDmg: Int16, secondaryMaxDmg: Int16)
}
