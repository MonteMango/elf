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

    private let gameService: any GameService
    private let progressionService: any ProgressionService

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
        progressionService.farmingLevel(exp: gameService.game.player.foragingExp)
    }

    public var foragingProgress: Double {
        progressionService.farmingProgress(exp: gameService.game.player.foragingExp)
    }

    public var fishingLevel: Int {
        progressionService.farmingLevel(exp: gameService.game.player.fishingExp)
    }

    public var fishingProgress: Double {
        progressionService.farmingProgress(exp: gameService.game.player.fishingExp)
    }

    public var miningLevel: Int {
        progressionService.farmingLevel(exp: gameService.game.player.miningExp)
    }

    public var miningProgress: Double {
        progressionService.farmingProgress(exp: gameService.game.player.miningExp)
    }

    // MARK: - Initialization

    public init(gameService: any GameService, progressionService: any ProgressionService) {
        self.gameService = gameService
        self.progressionService = progressionService
    }

    // MARK: - Actions

    public func advanceToNextDay() {
        gameService.advanceToNextDay()
        Task {
            try? await gameService.saveGame()
        }
    }
}
