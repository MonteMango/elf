//
//  ItemRarity.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import Foundation

public enum ItemRarity: String, Codable, Sendable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary
}
