//
//  CalendarService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import Foundation

/// Service for managing game calendar structure
public protocol CalendarService: Sendable {

    /// Number of days in one calendar iteration (week-like cycle).
    var daysPerIteration: Int { get }

    /// Generates full calendar for the game (160 days)
    func generateFullCalendar() -> [GameDay]
}
