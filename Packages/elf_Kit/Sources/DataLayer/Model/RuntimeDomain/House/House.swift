//
//  House.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Represents a house in the tournament
/// Each house has exactly 10 members (elves)
public struct House: Sendable, Identifiable, Equatable {

    // MARK: - Constants

    public static let membersCount = 10

    // MARK: - Properties

    public let id: HouseID
    public let name: String
    public let logoImageName: String
    public var isEliminated: Bool
    public var members: [ElfInfo]

    // MARK: - Initialization

    public init(
        id: HouseID = HouseID(),
        name: String,
        logoImageName: String,
        isEliminated: Bool = false,
        members: [ElfInfo]
    ) {
        precondition(members.count == House.membersCount, "House must have exactly \(House.membersCount) members")
        precondition(Set(members.map(\.id)).count == members.count, "House members must have unique ElfIDs")
        self.id = id
        self.name = name
        self.logoImageName = logoImageName
        self.isEliminated = isEliminated
        self.members = members
    }
}
