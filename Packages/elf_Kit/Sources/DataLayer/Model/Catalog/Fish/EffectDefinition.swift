//
//  EffectDefinition.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import Foundation

public struct EffectDefinition: Codable, Sendable, Identifiable {
    public let id: UUID
    public let effectType: String
    public let title: String
    public let description: String
}
