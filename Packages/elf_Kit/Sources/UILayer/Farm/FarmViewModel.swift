//
//  FarmViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 06.01.26.
//

import Dependencies
import Foundation

@MainActor
@Observable
public final class FarmViewModel {

    // MARK: - Dependencies (snapshotted at init)

    private let gameService: any GameService
    private let progressionService: any ProgressionService

    // MARK: - Farming Skills (computed reactively)

    public var foragingLevel: Int {
        progressionService.farmingLevel(exp: gameService.player.foragingExp)
    }
    public var foragingProgress: Double {
        progressionService.farmingProgress(exp: gameService.player.foragingExp)
    }
    public var fishingLevel: Int {
        progressionService.farmingLevel(exp: gameService.player.fishingExp)
    }
    public var fishingProgress: Double {
        progressionService.farmingProgress(exp: gameService.player.fishingExp)
    }
    public var miningLevel: Int {
        progressionService.farmingLevel(exp: gameService.player.miningExp)
    }
    public var miningProgress: Double {
        progressionService.farmingProgress(exp: gameService.player.miningExp)
    }

    // MARK: - Initialization

    public init(gameService: any GameService) {
        @Dependency(\.progressionService) var progressionService
        self.progressionService = progressionService

        self.gameService = gameService
    }
}
