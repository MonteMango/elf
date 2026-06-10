//
//  Material.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

public struct Material: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let imageName: String
    public let category: MaterialSubcategory
    public let description: String

    public init(
        id: UUID,
        title: String,
        imageName: String,
        category: MaterialSubcategory = .monsters,
        description: String = "Material for crafting"
    ) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.category = category
        self.description = description
    }

    // MARK: - Codable (backward compatible)

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageName
        case category
        case description
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        imageName = try container.decode(String.self, forKey: .imageName)
        // Default to .monsters for backward compatibility with existing JSON
        category = try container.decodeIfPresent(MaterialSubcategory.self, forKey: .category) ?? .monsters
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? "Material for crafting"
    }
}
