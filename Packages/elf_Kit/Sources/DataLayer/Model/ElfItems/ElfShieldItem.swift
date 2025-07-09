//
//  ElfShieldItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

public final class ElfShieldItem: ElfItem {
    public let id: UUID
    public let item: Item
    
    public let rune: Int? = nil
    
    public init(shieldItem: ShieldItem) {
        self.id = UUID()
        self.item = shieldItem
    }
}
