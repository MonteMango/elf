//
//  FarmViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import Foundation

@Observable
@MainActor
public final class FarmViewModel {

    // MARK: - Dependencies

    private let gameService: GameService

    // MARK: - Computed Properties

    public var currentActionPoints: Int {
        gameService.game.gameState.currentActionPoints
    }

    public var maxActionPoints: Int {
        gameService.game.gameState.maxActionPoints
    }

    public var isLastDay: Bool {
        gameService.game.gameState.isLastDay
    }

    // MARK: - Calendar Properties

    public var currentDay: GameDay {
        gameService.game.gameState.currentDay
    }

    public var upcomingDays: [GameDay] {
        gameService.game.gameState.upcomingDays
    }

    public var calendar: [GameDay] {
        gameService.game.gameState.calendar
    }

    // MARK: - Farming Skills

    public var foragingLevel: Int {
        gameService.game.player.foragingLevel
    }

    public var foragingProgress: Double {
        gameService.game.player.foragingProgress
    }

    public var fishingLevel: Int {
        gameService.game.player.fishingLevel
    }

    public var fishingProgress: Double {
        gameService.game.player.fishingProgress
    }

    public var miningLevel: Int {
        gameService.game.player.miningLevel
    }

    public var miningProgress: Double {
        gameService.game.player.miningProgress
    }

    // MARK: - Initialization

    public init(gameService: GameService) {
        self.gameService = gameService
    }

    // MARK: - Actions

    public func advanceToNextDay() {
        gameService.advanceToNextDay()
        Task {
            try? await gameService.saveGame()
        }
    }
}
