//
//  TypedID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Protocol marker for phantom types used with TypedID
public protocol IDType: Sendable {}

/// Type-safe wrapper for UUIDs using phantom types.
///
/// This prevents accidentally mixing up different ID types at compile time.
/// For example, `ElfID` and `MonsterID` are incompatible types even though
/// both wrap UUID internally.
///
/// ## Usage
/// ```swift
/// typealias ElfID = TypedID<ElfIDType>
/// typealias MonsterID = TypedID<MonsterIDType>
///
/// func findElf(id: ElfID) -> Elf?
/// func findMonster(id: MonsterID) -> Monster?
///
/// let elfId = ElfID()
/// let monsterId = MonsterID()
///
/// findElf(id: monsterId)  // Compile error!
/// ```
public struct TypedID<Tag: IDType>: Hashable, Sendable, Identifiable, CustomStringConvertible {

    /// The underlying UUID value
    public let rawValue: UUID

    /// Identifiable conformance
    public var id: TypedID<Tag> { self }

    /// Creates a new TypedID with a random UUID
    public init() {
        self.rawValue = UUID()
    }

    /// Creates a TypedID from an existing UUID
    /// - Parameter rawValue: The UUID to wrap
    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    /// String representation of the ID
    public var description: String {
        rawValue.uuidString
    }
}

// MARK: - Codable

extension TypedID: Codable {
    /// Decodes from a raw UUID string for backward compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(UUID.self)
    }

    /// Encodes as a raw UUID string for backward compatibility
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Comparable

extension TypedID: Comparable {
    public static func < (lhs: TypedID<Tag>, rhs: TypedID<Tag>) -> Bool {
        lhs.rawValue.uuidString < rhs.rawValue.uuidString
    }
}
