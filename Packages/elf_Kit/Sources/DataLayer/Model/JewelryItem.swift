//
//  JewelryItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.11.24.
//

import Foundation

public struct JewelryItem: Item {
    public let id: UUID
    public let title: String
    public let tier: Int16
    
    public let magicalDefensePoint: Int16
}
