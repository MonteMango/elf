//
//  DayType.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation
import SwiftUI

/// Types of game days with different activities
public enum DayType: Int, CaseIterable, Sendable, Codable {
    case normal = 0
    case dungeon = 1
    case randomEvent = 2
    case houseWar = 3

    /// Display name for the day type
    public var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .dungeon: return "Dungeon"
        case .randomEvent: return "Event"
        case .houseWar: return "War"
        }
    }

    /// Background color for calendar display
    public var backgroundColor: Color {
        switch self {
        case .normal: return .gray
        case .dungeon: return .purple
        case .randomEvent: return .blue
        case .houseWar: return .red
        }
    }
}
