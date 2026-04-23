//
//  CalendarViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 06.12.25.
//

import Dependencies
import Foundation

/// ViewModel for Calendar screen
@MainActor
@Observable
public final class CalendarViewModel {

    // MARK: - Types

    public enum ViewMode: Int, CaseIterable, Sendable {
        case line = 0
        case grid = 1

        public var title: String {
            switch self {
            case .line: return "Line"
            case .grid: return "Grid"
            }
        }

        public var iconName: String {
            switch self {
            case .line: return "rectangle.split.3x1"
            case .grid: return "calendar"
            }
        }
    }

    // MARK: - Dependencies

    @ObservationIgnored
    @Dependency(\.calendarService) private var calendarService

    // MARK: - State

    public var viewMode: ViewMode = .line

    // MARK: - Data

    public let calendar: [GameDay]
    public let currentDayNumber: Int

    public var daysPerIteration: Int { calendarService.daysPerIteration }

    // MARK: - Initialization

    public init(calendar: [GameDay], currentDayNumber: Int) {
        self.calendar = calendar
        self.currentDayNumber = currentDayNumber
    }
}
