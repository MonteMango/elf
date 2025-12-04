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

    public let id: UUID
    public let name: String
    public let logoImageName: String
    public var isEliminated: Bool
    public var members: [ElfInfo]

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        logoImageName: String,
        isEliminated: Bool = false,
        members: [ElfInfo]
    ) {
        precondition(members.count == House.membersCount, "House must have exactly \(House.membersCount) members")
        self.id = id
        self.name = name
        self.logoImageName = logoImageName
        self.isEliminated = isEliminated
        self.members = members
    }

    // MARK: - Computed Properties

    /// Number of alive members in the house
    public var aliveMembersCount: Int {
        members.filter { $0.currentHP > 0 }.count
    }

    /// Total level of all members
    public var totalLevel: Int {
        members.reduce(0) { $0 + Int($1.level) }
    }

    /// Average level of members
    public var averageLevel: Double {
        Double(totalLevel) / Double(House.membersCount)
    }
}
