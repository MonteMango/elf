//
//  GameStateSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

public struct GameStateSaveData: Codable, Sendable {
    public let currentDay: GameDaySaveData
    public let calendar: [GameDaySaveData]

    public init(from gameState: GameState) {
        self.currentDay = GameDaySaveData(from: gameState.currentDay)
        self.calendar = gameState.calendar.map { GameDaySaveData(from: $0) }
    }

    public func toGameState() -> GameState {
        GameState(
            currentDay: currentDay.toGameDay(),
            calendar: calendar.map { $0.toGameDay() }
        )
    }
}
