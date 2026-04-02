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

    // MARK: - Game State

    private var game: Game

    // MARK: - Computed Properties

    public var currentActionPoints: Int {
        game.gameState.currentActionPoints
    }

    public var maxActionPoints: Int {
        game.gameState.maxActionPoints
    }

    public var isLastDay: Bool {
        game.gameState.isLastDay
    }

    // MARK: - Calendar Properties

    public var currentDay: GameDay {
        game.gameState.currentDay
    }

    public var upcomingDays: [GameDay] {
        game.gameState.upcomingDays
    }

    public var calendar: [GameDay] {
        game.gameState.calendar
    }

    // MARK: - Farming Skills

    public var foragingLevel: Int = 1
    public var foragingProgress: Double = 0
    public var fishingLevel: Int = 1
    public var fishingProgress: Double = 0
    public var miningLevel: Int = 1
    public var miningProgress: Double = 0

    // MARK: - Initialization

    public init(gameService: any GameService, progressionService: any ProgressionService) {
        self.gameService = gameService
        self.progressionService = progressionService
        self.game = gameService.currentGame
    }

    // MARK: - Game State Observation

    public func observeGameState() async {
        await loadSkills()
        for await game in await gameService.gameUpdates() {
            self.game = game
        }
    }

    // MARK: - Data Loading

    public func loadSkills() async {
        let player = (await gameService.game).player
        foragingLevel = await progressionService.farmingLevel(exp: player.foragingExp)
        foragingProgress = await progressionService.farmingProgress(exp: player.foragingExp)
        fishingLevel = await progressionService.farmingLevel(exp: player.fishingExp)
        fishingProgress = await progressionService.farmingProgress(exp: player.fishingExp)
        miningLevel = await progressionService.farmingLevel(exp: player.miningExp)
        miningProgress = await progressionService.farmingProgress(exp: player.miningExp)
    }

    // MARK: - Actions

    public func advanceToNextDay() async {
        await gameService.advanceToNextDay()
        try? await gameService.saveGame()
    }
}
