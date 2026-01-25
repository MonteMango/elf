//
//  FarmActivityViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

@Observable
@MainActor
public final class FarmActivityViewModel {

    // MARK: - Dependencies

    private let gameService: any GameService
    private let fishRepository: (any FishRepository)?

    // MARK: - Activity

    public let activity: FarmActivity

    // MARK: - Skill Info

    public var skillTitle: String {
        "\(activity.title) skill"
    }

    public var skillLevel: Int {
        switch activity {
        case .fishing: return gameService.game.player.fishingLevel
        case .foraging: return gameService.game.player.foragingLevel
        case .mining: return gameService.game.player.miningLevel
        }
    }

    public var skillProgress: Double {
        switch activity {
        case .fishing: return gameService.game.player.fishingProgress
        case .foraging: return gameService.game.player.foragingProgress
        case .mining: return gameService.game.player.miningProgress
        }
    }

    public var skillExpInLevel: Int {
        switch activity {
        case .fishing: return gameService.game.player.fishingExp % 50
        case .foraging: return gameService.game.player.foragingExp % 50
        case .mining: return gameService.game.player.miningExp % 50
        }
    }

    public let expPerLevel: Int = 50

    // MARK: - Action

    public var actionButtonTitle: String { activity.title }
    public let actionCost: Int = 20

    public var canPerformAction: Bool {
        currentActionPoints >= actionCost
    }

    // MARK: - Warning

    public var warningText: String {
        "Monsters could attack you during \(activity.rawValue)."
    }

    // MARK: - Fish (only for fishing activity)

    public var availableFish: [Fish] {
        fishRepository?.getAllFish() ?? []
    }

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

    // MARK: - Initialization

    public init(activity: FarmActivity, gameService: any GameService, fishRepository: (any FishRepository)? = nil) {
        self.activity = activity
        self.gameService = gameService
        self.fishRepository = fishRepository
    }

    // MARK: - Actions

    public func advanceToNextDay() {
        gameService.advanceToNextDay()
        Task(priority: .userInitiated) {
            try? await gameService.saveGame()
        }
    }
}
