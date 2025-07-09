//
//  ElfDefenseItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

public final class ElfDefenseItem: ElfItem {
    public let id: UUID
    public let item: Item
    
    public let rune: Int? = nil
    
    public init(defenseItem: DefenseItem) {
        self.id = UUID()
        self.item = defenseItem
    }
}
