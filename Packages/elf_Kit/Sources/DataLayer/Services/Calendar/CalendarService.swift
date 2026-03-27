//
//  CalendarService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import Foundation

/// Service for managing game calendar structure
public protocol CalendarService: Sendable {

    /// Generates full calendar for the game (160 days)
    func generateFullCalendar() async -> [GameDay]
}
