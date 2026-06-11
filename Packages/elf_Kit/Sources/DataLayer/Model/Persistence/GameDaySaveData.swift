//
//  GameDaySaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

public struct GameDaySaveData: Codable, Sendable {
    public let id: GameDayID
    public let dayNumber: Int
    public let dayType: DayType

    public init(from gameDay: GameDay) {
        self.id = gameDay.id
        self.dayNumber = gameDay.dayNumber
        self.dayType = gameDay.dayType
    }

    public func toGameDay() -> GameDay {
        GameDay(
            id: id,
            dayNumber: dayNumber,
            dayType: dayType
        )
    }
}
