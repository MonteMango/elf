//
//  CalendarDayData.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// Simple data transfer object for calendar day display
public struct CalendarDayData: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let dayNumber: Int
    public let backgroundColor: Color

    public init(id: UUID = UUID(), dayNumber: Int, backgroundColor: Color = .white) {
        self.id = id
        self.dayNumber = dayNumber
        self.backgroundColor = backgroundColor
    }
}
