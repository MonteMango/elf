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

    /// Whether this is a fixed damage (min == max)
    public var isFixed: Bool {
        minimum == maximum
    }

    /// Private initializer
    private init(minimum: Int, maximum: Int) {
        self.minimum = minimum
        self.maximum = maximum
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
