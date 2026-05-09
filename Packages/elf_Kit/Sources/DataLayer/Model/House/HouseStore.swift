//
//  HouseStore.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation
import Observation

/// Runtime, observable wrapper over a `House` value. Holds the ten house
/// members as `ElfStore` references — the same instance is shared with
/// `GameStore.player` (which is just a computed accessor into one slot).
///
/// `House` (value-type) remains the on-disk and initial-creation shape;
/// `HouseStore.init(from:)` lifts it into runtime, and `snapshot()` writes
/// it back when persisting.
@MainActor
@Observable
public final class HouseStore: Identifiable {

    // MARK: - Stable identity / metadata

    public let id: UUID
    public let name: String
    public let logoImageName: String

    // MARK: - Mutable state

    public var isEliminated: Bool
    public var members: [ElfStore]

    // MARK: - Initialization

    public init(from house: House) {
        precondition(
            house.members.count == House.membersCount,
            "House must have exactly \(House.membersCount) members"
        )
        self.id = house.id
        self.name = house.name
        self.logoImageName = house.logoImageName
        self.isEliminated = house.isEliminated
        self.members = house.members.map { ElfStore(from: $0) }
    }

    // MARK: - Snapshot

    public func snapshot() -> House {
        House(
            id: id,
            name: name,
            logoImageName: logoImageName,
            isEliminated: isEliminated,
            members: members.map { $0.snapshot() }
        )
    }
}
