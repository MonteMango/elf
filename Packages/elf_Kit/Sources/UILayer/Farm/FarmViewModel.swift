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

    private let session: GameSession
    private let progressionService: any ProgressionService

    // MARK: - Farming Skills (computed reactively)

    public var foragingLevel: Int {
        progressionService.farmingLevel(exp: session.state.player.foragingExp)
    }
    public var foragingProgress: Double {
        progressionService.farmingProgress(exp: session.state.player.foragingExp)
    }
    public var fishingLevel: Int {
        progressionService.farmingLevel(exp: session.state.player.fishingExp)
    }
    public var fishingProgress: Double {
        progressionService.farmingProgress(exp: session.state.player.fishingExp)
    }
    public var miningLevel: Int {
        progressionService.farmingLevel(exp: session.state.player.miningExp)
    }
    public var miningProgress: Double {
        progressionService.farmingProgress(exp: session.state.player.miningExp)
    }

    // MARK: - Initialization

    public init(session: GameSession) {
        @Dependency(\.progressionService) var progressionService
        self.progressionService = progressionService

        self.session = session
    }
}
