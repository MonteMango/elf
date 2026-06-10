//
//  QuestCharacter.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct QuestCharacter: Codable, Sendable, Identifiable, Hashable {
    public let id: QuestCharacterID
    public let name: String
    public let title: String
    public let imageName: String

    public init(
        id: QuestCharacterID,
        name: String,
        title: String,
        imageName: String
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.imageName = imageName
    }
}
