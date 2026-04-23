//
//  GameSessionModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Non-optional owner of an active game session.
///
/// Wraps the session-scoped `gameService` and the shared `GameDayStateViewModel`,
/// and exposes factories for session-bound ViewModels. Because `gameService` is
/// non-optional, it is structurally impossible to build a session-bound ViewModel
/// without a live session — removing the need for runtime `fatalError` guards in
/// ViewModel factories.
///
/// Lifecycle: created when a game starts and released when it ends (see
/// `ElfGameContainer.startGameSession` / `endGameSession`).
@MainActor
@Observable
public final class GameSessionModel {

    // MARK: - Session State

    public let gameService: any GameService
    public let dayState: GameDayStateViewModel

    // MARK: - Initialization

    public init(gameService: any GameService) {
        self.gameService = gameService
        self.dayState = GameDayStateViewModel(gameService: gameService)
    }

    // MARK: - ViewModel Factories

    public func makeFarmViewModel() -> FarmViewModel {
        FarmViewModel(gameService: gameService)
    }

    public func makeFarmActivityViewModel(activity: FarmActivity) -> FarmActivityViewModel {
        FarmActivityViewModel(activity: activity, gameService: gameService)
    }
}
