//
//  DayType+Colors.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// UI-specific extension for DayType colors
/// Keeps SwiftUI dependency out of DataLayer
extension DayType {
    /// Background color for calendar display
    public var backgroundColor: Color {
        switch self {
        case .normal: return ElfColors.Calendar.normalDay
        case .dungeon: return ElfColors.Calendar.dungeonDay
        case .randomEvent: return ElfColors.Calendar.eventDay
        case .houseWar: return ElfColors.Calendar.houseWarDay
        case .unknown: return ElfColors.Calendar.unknownDay
        }
    }
}
