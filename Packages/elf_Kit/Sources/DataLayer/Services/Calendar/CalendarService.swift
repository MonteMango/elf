//
//  CalendarService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import Foundation

/// Service for managing game calendar structure
public protocol CalendarService: Sendable {

    /// Total number of days in the game (10 iterations × 16 days)
    var totalDays: Int { get }

    /// Number of days per iteration
    var daysPerIteration: Int { get }

    /// Total number of iterations (house war events)
    var totalIterations: Int { get }

    /// Generates full calendar for the game (160 days)
    func generateFullCalendar() -> [GameDay]

    /// Returns expected day type for a given day number based on fixed structure
    func dayType(for dayNumber: Int) -> DayType

    /// Updates day type in calendar (e.g., house war → dungeon based on battle results)
    func updateDayType(dayNumber: Int, newType: DayType, in calendar: inout [GameDay])
}
