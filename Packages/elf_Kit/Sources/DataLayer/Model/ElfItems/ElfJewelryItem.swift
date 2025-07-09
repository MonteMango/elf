//
//  ElfJewelryItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

public final class ElfJewelryItem: ElfItem {
    public let id: UUID
    public let item: Item
    
    public init(jewelryItem: JewelryItem) {
        self.id = UUID()
        self.item = jewelryItem
    }
}
