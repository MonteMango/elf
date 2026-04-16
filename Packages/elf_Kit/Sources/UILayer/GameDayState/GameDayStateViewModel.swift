//
//  GameDayStateViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Shared view model for the current-day state (action points, calendar position,
/// next-day transition). One instance lives on `ElfGameContainer` for the duration
/// of a game session and is reused by every screen that needs day context.
@MainActor
@Observable
public final class GameDayStateViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService

    // MARK: - Game Session State

    public var actionPoints: ActionPoints { gameService.actionPoints }
    public var currentDay: GameDay { gameService.currentDay }
    public var upcomingDays: [GameDay] { gameService.upcomingDays }
    public var calendar: [GameDay] { gameService.calendar }
    public var isLastDay: Bool { gameService.isLastDay }

    // MARK: - Initialization

    public init(gameService: any GameService) {
        self.gameService = gameService
    }

    // MARK: - Actions

    public func advanceToNextDay() async {
        gameService.advanceToNextDay()
        try? await gameService.saveGame()
    }
}
