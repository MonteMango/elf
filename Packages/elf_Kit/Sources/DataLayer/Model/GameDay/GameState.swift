//
//  GameState.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import Foundation

/// Game state containing current day, action points, and upcoming days schedule
public struct GameState: Sendable {
    public var currentDay: GameDay
    public var currentActionPoints: Int
    public var maxActionPoints: Int
    public var upcomingDays: [GameDay]

    public init(
        currentDay: GameDay,
        currentActionPoints: Int,
        maxActionPoints: Int,
        upcomingDays: [GameDay]
    ) {
        self.currentDay = currentDay
        self.currentActionPoints = currentActionPoints
        self.maxActionPoints = maxActionPoints
        self.upcomingDays = upcomingDays
    }

    /// Progress of action points as a ratio (0.0 to 1.0)
    public var actionPointsProgress: Double {
        guard maxActionPoints > 0 else { return 0 }
        return Double(currentActionPoints) / Double(maxActionPoints)
    }
}
