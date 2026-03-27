//
//  DefaultCalendarService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import Foundation

/// Default implementation of CalendarService
///
/// Calendar structure per iteration (16 days):
/// - Days 1, 2, 3: Normal
/// - Day 4: Dungeon
/// - Days 5, 6, 7: Normal
/// - Day 8: Random Event
/// - Days 9, 10, 11: Normal
/// - Day 12: Dungeon
/// - Days 13, 14, 15: Normal
/// - Day 16: House War (may become Dungeon based on battle results)
public final class DefaultCalendarService: CalendarService {

    // MARK: - CalendarService Properties

    public let daysPerIteration: Int = 16

    // MARK: - Private Properties

    private let totalDays: Int = 160

    // MARK: - Initialization

    public init() {}

    // MARK: - CalendarService Methods

    public func generateFullCalendar() async -> [GameDay] {
        (1...totalDays).map { dayNumber in
            GameDay(dayNumber: dayNumber, dayType: dayType(for: dayNumber))
        }
    }

    // MARK: - Private Helpers

    private func dayType(for dayNumber: Int) -> DayType {
        // Position within iteration (1-16)
        let positionInIteration = ((dayNumber - 1) % daysPerIteration) + 1

        switch positionInIteration {
        case 4, 12:
            return .dungeon
        case 8:
            return .randomEvent
        case 16:
            return .houseWar
        default:
            return .normal
        }
    }
}
