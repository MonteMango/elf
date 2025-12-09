//
//  Material.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

// MARK: - Material

public struct Material: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let imageName: String

    public init(id: UUID, title: String, imageName: String) {
        self.id = id
        self.title = title
        self.imageName = imageName
    }
}

// MARK: - MaterialsData

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
