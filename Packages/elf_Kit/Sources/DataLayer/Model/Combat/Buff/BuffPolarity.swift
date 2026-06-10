//
//  BuffPolarity.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Whether the buff is helpful (`positive`) or harmful (`negative`).
public enum BuffPolarity: String, Codable, Sendable, Hashable {
    case positive
    case negative
}
