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

    public init(id: UUID, title: String, imageName: String) {
        self.id = id
        self.title = title
        self.imageName = imageName
    }
}
