//
//  GameDay.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation

/// Represents a single game day
public struct GameDay: Sendable, Identifiable, Equatable, Codable {
    public let id: UUID
    public let dayNumber: Int
    public let dayType: DayType

    public init(
        id: UUID = UUID(),
        dayNumber: Int,
        dayType: DayType
    ) {
        self.id = id
        self.dayNumber = dayNumber
        self.dayType = dayType
    }
}
