//
//  CalendarDayData.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Simple data transfer object for calendar day display
public struct CalendarDayData: Identifiable, Sendable {
    public let id: UUID
    public let dayNumber: Int

    public init(id: UUID = UUID(), dayNumber: Int) {
        self.id = id
        self.dayNumber = dayNumber
    }
}
