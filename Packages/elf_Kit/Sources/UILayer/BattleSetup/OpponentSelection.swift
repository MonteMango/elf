//
//  OpponentSelection.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

/// Represents the selected opponent type for battle
public enum OpponentSelection: Hashable, Sendable {
    /// Use the configured elf bot (right panel configuration)
    case elf

    /// Fight against a specific monster
    case monster(Monster)

    /// Display name for the picker
    public var displayName: String {
        switch self {
        case .elf:
            return "Elf"
        case .monster(let monster):
            return monster.title
        }
    }
}
