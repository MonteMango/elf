//
//  MaterialsData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

public struct MaterialsData: Codable, Sendable {
    public let version: String
    public let monstersDrop: [Material]

    enum CodingKeys: String, CodingKey {
        case version
        case monstersDrop = "monsters_drop"
    }

    /// Empty initializer for fallback
    public init() {
        self.version = "1.0-empty"
        self.monstersDrop = []
    }

    public init(version: String, monstersDrop: [Material]) {
        self.version = version
        self.monstersDrop = monstersDrop
    }
}
