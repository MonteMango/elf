//
//  ActionPoints.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Action points with current and maximum bounds.
///
/// This type ensures that:
/// - Maximum is always positive
/// - Current is always between 0 and maximum
/// - Operations maintain these invariants
///
/// ## Usage
/// ```swift
/// let ap = ActionPoints.create(current: 5, maximum: 10)
/// switch ap {
/// case .success(let points):
///     let afterSpend = points.spend(3)  // Result<ActionPoints, Error>
///     let afterRest = points.restore(2)  // ActionPoints (clamped to max)
/// case .failure(let error):
///     handleError(error)
/// }
/// ```
public struct ActionPoints: Sendable, Hashable, Equatable {

    /// Current action points (0 <= current <= maximum)
    public let current: Int

    /// Maximum action points (always > 0)
    public let maximum: Int

    /// Progress as a percentage (0.0 to 1.0)
    public var progress: Double {
        guard maximum > 0 else { return 0 }
        return Double(current) / Double(maximum)
    }

    /// Whether all action points have been spent
    public var isEmpty: Bool { current <= 0 }

    /// Whether action points are at maximum
    public var isFull: Bool { current >= maximum }

    /// How many action points are remaining
    public var remaining: Int { current }

    /// Private initializer — use `create` to make instances
    private init(current: Int, maximum: Int) {
        self.current = current
        self.maximum = maximum
    }

    /// Creates ActionPoints with validation.
    ///
    /// - Parameters:
    ///   - current: Current points (will be clamped to 0...maximum)
    ///   - maximum: Maximum points (must be > 0)
    /// - Returns: A Result containing ActionPoints or an error
    public static func create(current: Int, maximum: Int) -> Result<ActionPoints, ActionPointsError> {
        guard maximum > 0 else {
            return .failure(.invalidMaximum)
        }

        let clampedCurrent = max(0, min(current, maximum))
        return .success(ActionPoints(current: clampedCurrent, maximum: maximum))
    }

    /// Creates ActionPoints at full capacity.
    ///
    /// - Parameter maximum: Maximum points (must be > 0)
    /// - Returns: A Result containing full ActionPoints or an error
    public static func full(maximum: Int) -> Result<ActionPoints, ActionPointsError> {
        create(current: maximum, maximum: maximum)
    }

    /// Creates ActionPoints at zero.
    ///
    /// - Parameter maximum: Maximum points (must be > 0)
    /// - Returns: A Result containing empty ActionPoints or an error
    public static func empty(maximum: Int) -> Result<ActionPoints, ActionPointsError> {
        create(current: 0, maximum: maximum)
    }

    /// Unsafe creation for internal use (e.g., loading from storage).
    /// - Parameters:
    ///   - current: Current points
    ///   - maximum: Maximum points
    /// - Returns: ActionPoints with values clamped to valid range
    public static func unsafeCreate(current: Int, maximum: Int) -> ActionPoints {
        let safeMax = max(1, maximum)
        let safeCurrent = max(0, min(current, safeMax))
        return ActionPoints(current: safeCurrent, maximum: safeMax)
    }

    /// Spends the specified amount of action points.
    ///
    /// - Parameter amount: The amount to spend (must be > 0)
    /// - Returns: A Result with the new ActionPoints or an error if insufficient
    public func spend(_ amount: Int) -> Result<ActionPoints, ActionPointsError> {
        guard amount > 0 else { return .success(self) }
        guard current >= amount else {
            return .failure(.insufficientPoints(required: amount, available: current))
        }
        return .success(ActionPoints(current: current - amount, maximum: maximum))
    }

    /// Restores the specified amount of action points (clamped to maximum).
    ///
    /// - Parameter amount: The amount to restore
    /// - Returns: New ActionPoints with restored value
    public func restore(_ amount: Int) -> ActionPoints {
        let newCurrent = min(current + max(0, amount), maximum)
        return ActionPoints(current: newCurrent, maximum: maximum)
    }

    /// Resets action points to maximum.
    ///
    /// - Returns: New ActionPoints at full capacity
    public func reset() -> ActionPoints {
        ActionPoints(current: maximum, maximum: maximum)
    }

    /// Creates a copy with a new maximum (current is clamped if needed).
    ///
    /// - Parameter newMaximum: The new maximum value
    /// - Returns: Result with adjusted ActionPoints or error
    public func withMaximum(_ newMaximum: Int) -> Result<ActionPoints, ActionPointsError> {
        ActionPoints.create(current: current, maximum: newMaximum)
    }
}

// MARK: - Error

/// Errors that can occur with ActionPoints operations
public enum ActionPointsError: Error, Equatable, Sendable, LocalizedError {
    /// Maximum must be positive
    case invalidMaximum

    /// Current cannot be negative
    case negativeCurrent

    /// Not enough points to spend
    case insufficientPoints(required: Int, available: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidMaximum:
            return "Maximum action points must be greater than zero"
        case .negativeCurrent:
            return "Current action points cannot be negative"
        case .insufficientPoints(let required, let available):
            return "Insufficient action points: need \(required), have \(available)"
        }
    }
}

// MARK: - Comparable

extension ActionPoints: Comparable {
    public static func < (lhs: ActionPoints, rhs: ActionPoints) -> Bool {
        lhs.current < rhs.current
    }
}

// MARK: - Codable

extension ActionPoints: Codable {
    enum CodingKeys: String, CodingKey {
        case current
        case maximum
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let current = try container.decode(Int.self, forKey: .current)
        let maximum = try container.decode(Int.self, forKey: .maximum)
        self = ActionPoints.unsafeCreate(current: current, maximum: maximum)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(current, forKey: .current)
        try container.encode(maximum, forKey: .maximum)
    }
}

// MARK: - CustomStringConvertible

extension ActionPoints: CustomStringConvertible {
    public var description: String {
        "\(current)/\(maximum)"
    }
}
