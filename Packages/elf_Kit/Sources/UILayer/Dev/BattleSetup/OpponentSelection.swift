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
}
