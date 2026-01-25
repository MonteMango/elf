//
//  ItemRarity+CardBorder.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI

extension ItemRarity {
    /// Converts ItemRarity to ItemCardColor.RarityLevel for UI display.
    var cardRarityLevel: ItemCardColor.RarityLevel {
        switch self {
        case .common: return .common
        case .uncommon: return .uncommon
        case .rare: return .rare
        case .epic: return .epic
        case .legendary: return .legendary
        }
    }
}
