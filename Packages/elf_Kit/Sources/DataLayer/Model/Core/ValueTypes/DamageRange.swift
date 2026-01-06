//
//  DamageRange.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// A validated damage range with minimum and maximum bounds.
///
/// This type ensures that:
/// - Minimum is always >= 0
/// - Maximum is always >= minimum
///
/// ## Usage
/// ```swift
/// let range = DamageRange.create(minimum: 10, maximum: 20)
/// switch range {
/// case .success(let dmg):
///     print("Damage: \(dmg.minimum)-\(dmg.maximum)")
///     print("Average: \(dmg.average)")
/// case .failure(let error):
///     handleError(error)
/// }
/// ```
public struct DamageRange: Sendable, Hashable, Equatable {

    /// Minimum damage (always >= 0)
    public let minimum: Int

    /// Maximum damage (always >= minimum)
    public let maximum: Int

    /// Average damage
    public var average: Double {
        Double(minimum + maximum) / 2.0
    }

    /// Damage spread (max - min)
    public var spread: Int {
        maximum - minimum
    }

    /// Whether this is a fixed damage (min == max)
    public var isFixed: Bool {
        minimum == maximum
    }

    /// Private initializer
    private init(minimum: Int, maximum: Int) {
        self.minimum = minimum
        self.maximum = maximum
    }

    /// Creates a DamageRange with validation.
    ///
    /// - Parameters:
    ///   - minimum: Minimum damage (must be >= 0)
    ///   - maximum: Maximum damage (must be >= minimum)
    /// - Returns: Result containing DamageRange or error
    public static func create(minimum: Int, maximum: Int) -> Result<DamageRange, DamageRangeError> {
        guard minimum >= 0 else {
            return .failure(.negativeMinimum)
        }
        guard maximum >= minimum else {
            return .failure(.maximumLessThanMinimum)
        }
        return .success(DamageRange(minimum: minimum, maximum: maximum))
    }

    /// Creates a fixed damage (min == max).
    ///
    /// - Parameter value: The fixed damage value
    /// - Returns: Result containing DamageRange or error
    public static func fixed(_ value: Int) -> Result<DamageRange, DamageRangeError> {
        create(minimum: value, maximum: value)
    }

    /// Unsafe creation for internal use (e.g., loading from JSON).
    /// Values are clamped to valid range.
    ///
    /// - Parameters:
    ///   - minimum: Minimum damage
    ///   - maximum: Maximum damage
    /// - Returns: DamageRange with clamped values
    public static func unsafeCreate(minimum: Int, maximum: Int) -> DamageRange {
        let safeMin = max(0, minimum)
        let safeMax = max(safeMin, maximum)
        return DamageRange(minimum: safeMin, maximum: safeMax)
    }

    /// Zero damage range
    public static let zero = DamageRange(minimum: 0, maximum: 0)

    /// Adds a flat bonus to both minimum and maximum.
    ///
    /// - Parameter bonus: The bonus to add
    /// - Returns: New DamageRange with bonus applied
    public func adding(_ bonus: Int) -> DamageRange {
        let newMin = max(0, minimum + bonus)
        let newMax = max(newMin, maximum + bonus)
        return DamageRange(minimum: newMin, maximum: newMax)
    }

    /// Multiplies both minimum and maximum by a factor.
    ///
    /// - Parameter factor: The multiplication factor
    /// - Returns: New DamageRange with factor applied
    public func multiplied(by factor: Double) -> DamageRange {
        let newMin = max(0, Int((Double(minimum) * factor).rounded()))
        let newMax = max(newMin, Int((Double(maximum) * factor).rounded()))
        return DamageRange(minimum: newMin, maximum: newMax)
    }

    /// Combines two damage ranges.
    ///
    /// - Parameter other: The other range to add
    /// - Returns: Combined DamageRange
    public static func + (lhs: DamageRange, rhs: DamageRange) -> DamageRange {
        DamageRange(
            minimum: lhs.minimum + rhs.minimum,
            maximum: lhs.maximum + rhs.maximum
        )
    }
}

// MARK: - Error

/// Errors that can occur when creating a DamageRange
public enum DamageRangeError: Error, Equatable, Sendable, LocalizedError {
    /// Minimum damage cannot be negative
    case negativeMinimum

    /// Maximum must be >= minimum
    case maximumLessThanMinimum

    public var errorDescription: String? {
        switch self {
        case .negativeMinimum:
            return "Minimum damage cannot be negative"
        case .maximumLessThanMinimum:
            return "Maximum damage must be greater than or equal to minimum"
        }
    }
}

// MARK: - Codable

extension DamageRange: Codable {
    enum CodingKeys: String, CodingKey {
        case minimum
        case maximum
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let minimum = try container.decode(Int.self, forKey: .minimum)
        let maximum = try container.decode(Int.self, forKey: .maximum)
        self = DamageRange.unsafeCreate(minimum: minimum, maximum: maximum)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minimum, forKey: .minimum)
        try container.encode(maximum, forKey: .maximum)
    }
}

// MARK: - CustomStringConvertible

extension DamageRange: CustomStringConvertible {
    public var description: String {
        if isFixed {
            return "\(minimum)"
        }
        return "\(minimum)-\(maximum)"
    }
}
