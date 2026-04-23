//
//  GameSessionModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// Non-optional owner of an active game session.
///
/// Wraps the session-scoped `gameService`, the shared `GameDayStateViewModel`,
/// and the session-scoped `EquipmentService`. Exposes factories for session-bound
/// ViewModels. Because `gameService` is non-optional, it is structurally impossible
/// to build a session-bound ViewModel without a live session — removing the need
/// for runtime `fatalError` guards in ViewModel factories.
///
/// Lifecycle: created when a game starts and released when it ends (see
/// `ElfGameContainer.startGameSession` / `endGameSession`).
@MainActor
@Observable
public final class GameSessionModel {

    // MARK: - Session State

    public let gameService: any GameService
    public let dayState: GameDayStateViewModel
    public let equipmentService: any EquipmentService

    // MARK: - Initialization

    public init(gameService: any GameService) {
        @Dependency(\.itemsRepository) var itemsRepository
        self.gameService = gameService
        self.dayState = GameDayStateViewModel(gameService: gameService)
        self.equipmentService = DefaultEquipmentService(
            gameService: gameService,
            itemsRepository: itemsRepository
        )
    }

    // MARK: - ViewModel Factories

    public func makeFarmViewModel() -> FarmViewModel {
        FarmViewModel(gameService: gameService)
    }

    public func makeFarmActivityViewModel(activity: FarmActivity) -> FarmActivityViewModel {
        FarmActivityViewModel(activity: activity, gameService: gameService)
    }

    public func makeHuntViewModel() -> HuntViewModel {
        HuntViewModel(gameService: gameService)
    }

    public func makeCraftViewModel() -> CraftViewModel {
        CraftViewModel(gameService: gameService)
    }

    public func makeQuestViewModel(questId: QuestID) -> QuestViewModel {
        QuestViewModel(questId: questId, gameService: gameService)
    }

    public func makeQuestListViewModel() -> QuestListViewModel {
        QuestListViewModel(gameService: gameService)
    }

    public func makeGameDayViewModel() -> GameDayViewModel {
        GameDayViewModel(gameService: gameService)
    }

    public func makeCalendarViewModel(calendar: [GameDay], currentDayNumber: Int) -> CalendarViewModel {
        CalendarViewModel(calendar: calendar, currentDayNumber: currentDayNumber)
    }

    public func makeInventoryViewModel() -> InventoryViewModel {
        InventoryViewModel(gameService: gameService, equipmentService: equipmentService)
    }
}
