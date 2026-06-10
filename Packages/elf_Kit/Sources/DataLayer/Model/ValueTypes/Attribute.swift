//
//  Attribute.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// A non-negative attribute value for character stats (strength, agility, etc.)
///
/// This wrapper ensures that attribute values cannot be negative and provides
/// arithmetic operations that maintain this invariant.
///
/// ## Usage
/// ```swift
/// let strength: Attribute = 10
/// let bonus: Attribute = 5
/// let total = strength + bonus  // Attribute(15)
///
/// let reduced = strength - Attribute(15)  // Attribute(0), clamped to non-negative
/// ```
public struct Attribute: Sendable, Hashable, Equatable {

    /// The underlying value (always >= 0)
    public let value: Int16

    /// Zero attribute value
    public static let zero = Attribute(0)

    /// Creates an attribute, clamping negative values to 0
    /// - Parameter value: The raw value (will be clamped if negative)
    public init(_ value: Int16) {
        self.value = max(0, value)
    }

    /// Convenience accessor for Int value
    public var intValue: Int {
        Int(value)
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension Attribute: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int16) {
        self.init(value)
    }
}

// MARK: - Comparable

extension Attribute: Comparable {
    public static func < (lhs: Attribute, rhs: Attribute) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - AdditiveArithmetic

extension Attribute: AdditiveArithmetic {
    public static func + (lhs: Attribute, rhs: Attribute) -> Attribute {
        // Use Int to prevent overflow
        let sum = Int(lhs.value) + Int(rhs.value)
        return Attribute(Int16(clamping: sum))
    }

    public static func - (lhs: Attribute, rhs: Attribute) -> Attribute {
        // Clamp to 0 if result would be negative
        let diff = Int(lhs.value) - Int(rhs.value)
        return Attribute(Int16(max(0, diff)))
    }
}

// MARK: - Int16 Operations

extension Attribute {
    /// Adds an Int16 value in place
    public static func += (lhs: inout Attribute, rhs: Int16) {
        lhs = lhs + Attribute(rhs)
    }
}

// MARK: - Codable

extension Attribute: Codable {
    /// Decodes from a raw Int16 for backward compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int16.self)
        self.init(rawValue)
    }

    /// Encodes as a raw Int16 for backward compatibility
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - CustomStringConvertible

extension Attribute: CustomStringConvertible {
    public var description: String {
        "\(value)"
    }
}
