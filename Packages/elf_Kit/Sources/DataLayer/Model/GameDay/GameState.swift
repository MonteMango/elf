//
//  GameState.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation

/// Game state containing current day, action points, and full calendar
public struct GameState: Sendable, Codable, Equatable {
    public var currentDay: GameDay
    public var currentActionPoints: Int
    public var maxActionPoints: Int
    public var calendar: [GameDay]

    public init(
        currentDay: GameDay,
        currentActionPoints: Int,
        maxActionPoints: Int,
        calendar: [GameDay]
    ) {
        self.currentDay = currentDay
        self.currentActionPoints = currentActionPoints
        self.maxActionPoints = maxActionPoints
        self.calendar = calendar
    }

    /// Progress of action points as a ratio (0.0 to 1.0)
    public var actionPointsProgress: Double {
        guard maxActionPoints > 0 else { return 0 }
        return Double(currentActionPoints) / Double(maxActionPoints)
    }

    /// Next 3 days after current day (computed for backward compatibility)
    public var upcomingDays: [GameDay] {
        guard let currentIndex = calendar.firstIndex(where: { $0.dayNumber == currentDay.dayNumber }) else {
            return []
        }
        let nextIndex = currentIndex + 1
        guard nextIndex < calendar.count else { return [] }
        let endIndex = min(nextIndex + 3, calendar.count)
        return Array(calendar[nextIndex..<endIndex])
    }

    /// Whether current day is the last day in the calendar
    public var isLastDay: Bool {
        guard let lastDay = calendar.last else { return false }
        return currentDay.dayNumber >= lastDay.dayNumber
    }
}
