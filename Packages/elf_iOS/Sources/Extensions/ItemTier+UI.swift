//
//  ItemTier+UI.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

extension ItemTier {
    var color: Color {
        ElfColors.Tier.color(for: rawValue)
    }

    var displayName: String {
        switch self {
        case .legendary: "Legendary"
        case .rare: "Rare"
        case .uncommon: "Uncommon"
        case .common: "Common"
        }
    }

    var cardColor: ItemCardColor {
        .tier(rawValue)
    }
}
