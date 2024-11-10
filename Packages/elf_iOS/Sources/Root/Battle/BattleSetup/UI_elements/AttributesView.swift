//
//  AttributesView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 07.11.24.
//

import elf_Kit

internal protocol AttributesView {
    func updateAttributes(fightStyleAttributes: HeroAttributes?, levelRandomAttributes: [Int16: HeroAttributes]?, itemsAttributes: HeroAttributes?)
}
