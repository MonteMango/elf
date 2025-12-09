//
//  MonsterDisplayData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

/// Display data for MonsterCell - contains only what the View needs
/// This struct follows MVVM pattern: View should not know about Repositories
public struct MonsterDisplayData: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let imageName: String
    public let dropImageNames: [String]

    public init(id: UUID, title: String, imageName: String, dropImageNames: [String]) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.dropImageNames = dropImageNames
    }
}
