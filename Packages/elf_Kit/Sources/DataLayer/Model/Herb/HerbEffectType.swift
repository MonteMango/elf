//
//  HerbEffectType.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public enum HerbEffectType: String, Codable, Sendable, CaseIterable {
    case healing
    case stamina
    case strength
    case defense
    case speed
    case antidote
    case luck
    case mana
}
