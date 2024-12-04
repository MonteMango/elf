//
//  ElfItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 17.11.24.
//

public struct DefenseElfItem {
    let heroItem: DefenseItem
    let attributeLevel: ItemAttributeLevel<DefenseItemAttribute>?
}

public struct JewelryElfItem {
    let heroItem: JewelryItem
    let attributeLevel: ItemAttributeLevel<JewelryItemAttribute>
}

public enum ItemAttributeLevel<T> {
    case level1(first: T)
    case level2(first: T, second: T)
    case level3(first: T, second :T, third: T)
    case level3(first: T, second: T, third: T, fourth: T)
}
    
public enum DefenseItemAttribute {
    case strength
    case agility
    case power
    case instinct
}

public enum JewelryItemAttribute {
    case manaPoints
    case hitPoints
    case injuryResistance
    case injuryInflict
}


