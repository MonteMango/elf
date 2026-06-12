//
//  GameState.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation

/// Game state containing current day and full calendar.
///
/// Action points are **not** held here anymore — they live per-elf on
/// `ElfInfo.actionPoints` (the player's pool is the player elf's pool).
public struct GameState: Sendable, Equatable, Codable {
    public var currentDay: GameDay
    public var calendar: [GameDay]

    public init(
        currentDay: GameDay,
        calendar: [GameDay]
    ) {
        self.currentDay = currentDay
        self.calendar = calendar
    }

    // MARK: - Convenience Accessors

    /// Next 3 days after current day (computed for backward compatibility)
    public var upcomingDays: [GameDay] {
        guard let currentIndex = calendar.firstIndex(where: { $0.dayNumber == currentDay.dayNumber }) else {
            return []
        }
        let nextIndex = currentIndex + 1
        guard nextIndex < calendar.count else { return [] }
        let endIndex = min(nextIndex + GameMechanicsConstants.upcomingDaysCount, calendar.count)
        return Array(calendar[nextIndex..<endIndex])
    }

    /// Whether current day is the last day in the calendar
    public var isLastDay: Bool {
        guard let lastDay = calendar.last else { return false }
        return currentDay.dayNumber >= lastDay.dayNumber
    }
}
