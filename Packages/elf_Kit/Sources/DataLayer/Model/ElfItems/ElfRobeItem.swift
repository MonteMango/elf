//
//  ElfRobeItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 27.05.25.
//

import Foundation

public final class ElfRobeItem: ElfItem {
    public let id: UUID
    public let item: Item
    
    public init(robeItem: RobeItem) {
        self.id = UUID()
        self.item = robeItem
    }
}
