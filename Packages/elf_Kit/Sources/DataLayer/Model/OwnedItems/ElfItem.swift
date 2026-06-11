//
//  ElfItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.06.25.
//

import Foundation

public protocol ElfItem {
    var id: OwnedItemID { get }
    var item: Item { get }
}
