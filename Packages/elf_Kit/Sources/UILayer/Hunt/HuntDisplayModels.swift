//
//  HuntDisplayModels.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import Foundation

/// Display data for a single drop item.
///
/// `id` is a stable position-based key (e.g. `"weapon-0"`, `"material-2"`) assigned
/// by the producer from the immutable `monster.drops` layout — NOT derived from
/// `imageName`, so duplicate icons across slots are allowed without `ForEach` collisions.
public struct DropDisplay: Identifiable, Equatable, Sendable {
    public let id: String
    public let imageName: String
    public let tier: Int

    public init(id: String, imageName: String, tier: Int) {
        self.id = id
        self.imageName = imageName
        self.tier = tier
    }
}

/// Display data for MonsterCell - contains only what the View needs
/// This struct follows MVVM pattern: View should not know about Repositories
public struct MonsterDisplay: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let imageName: String
    public let drops: [DropDisplay]

    public init(id: UUID, title: String, imageName: String, drops: [DropDisplay]) {
        self.id = id
        self.title = title
        self.imageName = imageName
        self.drops = drops
    }
}
