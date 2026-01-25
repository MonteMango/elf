//
//  MonsterDisplayData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

/// Display data for a single drop item
public struct DropDisplayData: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let imageName: String
    public let tier: Int

    public init(id: UUID = UUID(), imageName: String, tier: Int) {
        self.id = id
        self.imageName = imageName
        self.tier = tier
    }
}

/// Display data for MonsterCell - contains only what the View needs
/// This struct follows MVVM pattern: View should not know about Repositories
public struct MonsterDisplayData: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let imageName: String
    public let drops: [DropDisplayData]

    public init(id: UUID, title: String, imageName: String, drops: [DropDisplayData]) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.drops = drops
    }
}
