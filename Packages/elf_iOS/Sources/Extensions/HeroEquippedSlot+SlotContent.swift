//
//  HeroEquippedSlot+SlotContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI

extension HeroEquippedSlot {
    /// Bridges the elf_Kit display DTO into the elf_SwiftUI rendering primitive.
    /// Used by `HeroSection`, `SquadElfCell` and `CombatantBodyView` to feed
    /// `EquipmentSlotView` without repeating the field-by-field mapping.
    var slotContent: EquipmentSlotView.ItemContent {
        .init(imageName: imageName, isMirror: isMirror)
    }
}
