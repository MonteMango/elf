//
//  HitPoints.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Health points with current and maximum tracking.
///
/// Unlike ActionPoints, current HP can go below zero (for overkill tracking)
/// but maximum is always positive.
///
/// ## Usage
/// ```swift
/// let hp = HitPoints.full(maximum: 100)
/// let afterDamage = hp.damage(30)  // HitPoints(current: 70, maximum: 100)
/// let afterHeal = afterDamage.heal(10)  // HitPoints(current: 80, maximum: 100)
///
/// if hp.isDead { showDeathScreen() }
/// ```
public struct HitPoints: Sendable, Hashable, Equatable {

    /// Current hit points (can be <= 0 when dead)
    public let current: Int

    /// Maximum hit points (always > 0)
    public let maximum: Int

    /// Health percentage (0.0 to 1.0, clamped)
    public var progress: Double {
        guard maximum > 0 else { return 0 }
        return max(0, min(Double(current) / Double(maximum), 1.0))
    }

    /// Whether the entity is alive (current > 0)
    public var isAlive: Bool { current > 0 }

    /// Whether the entity is dead (current <= 0)
    public var isDead: Bool { current <= 0 }

    /// Whether HP is at maximum
    public var isFull: Bool { current >= maximum }

    /// Amount of missing HP
    public var missing: Int { max(0, maximum - current) }

    /// Private initializer
    private init(current: Int, maximum: Int) {
        self.current = current
        self.maximum = max(1, maximum)
    }

    /// Creates HitPoints with specified values.
    ///
    /// - Parameters:
    ///   - current: Current HP (will be clamped to maximum but can be negative)
    ///   - maximum: Maximum HP (must be > 0)
    /// - Returns: HitPoints instance
    public static func create(current: Int, maximum: Int) -> HitPoints {
        let safeMax = max(1, maximum)
        let clampedCurrent = min(current, safeMax)
        return HitPoints(current: clampedCurrent, maximum: safeMax)
    }

}

// MARK: - Comparable

extension HitPoints: Comparable {
    public static func < (lhs: HitPoints, rhs: HitPoints) -> Bool {
        lhs.current < rhs.current
    }
}

// MARK: - Codable

extension HitPoints: Codable {
    enum CodingKeys: String, CodingKey {
        case current
        case maximum
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let current = try container.decode(Int.self, forKey: .current)
        let maximum = try container.decode(Int.self, forKey: .maximum)
        self = HitPoints.create(current: current, maximum: maximum)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(current, forKey: .current)
        try container.encode(maximum, forKey: .maximum)
    }
}

// MARK: - CustomStringConvertible

extension HitPoints: CustomStringConvertible {
    public var description: String {
        "\(max(0, current))/\(maximum)"
    }
}
