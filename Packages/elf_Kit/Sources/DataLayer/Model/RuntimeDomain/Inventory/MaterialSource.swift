//
//  MaterialSource.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.12.25.
//

import Foundation

/// Identifies which game data repository a material originates from.
public enum MaterialSource: String, Codable, Sendable, Hashable {
    case monster
    case fish
    case herb
    case ore
}
