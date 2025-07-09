//
//  ElfWeaponItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

public final class ElfWeaponItem: ElfItem {
    public let id: UUID
    public let item: Item
    
    public let enchantLevel: Int
    
    public init(weaponItem: WeaponItem) {
        self.id = UUID()
        self.item = weaponItem
        
        self.enchantLevel = 0
    }
}
