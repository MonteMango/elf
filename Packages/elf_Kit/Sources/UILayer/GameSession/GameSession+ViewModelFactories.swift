//
//  GameSession+ViewModelFactories.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// UI-layer extension on `GameSession` that vends ViewModels for screens.
/// Lives in `UILayer/` (not next to `GameSession` itself in `DataLayer/`) to
/// keep `GameSession`'s data-layer file free of references to UI types.
@MainActor
extension GameSession {

    public func makeFarmViewModel() -> FarmViewModel {
        FarmViewModel(session: self)
    }

    public func makeFarmActivityViewModel(activity: FarmActivity) -> FarmActivityViewModel {
        FarmActivityViewModel(activity: activity, session: self)
    }

    public func makeHuntViewModel() -> HuntViewModel {
        HuntViewModel(session: self)
    }

    public func makeCraftViewModel() -> CraftViewModel {
        CraftViewModel(session: self)
    }

    public func makeQuestViewModel(questId: QuestID) -> QuestViewModel {
        QuestViewModel(questId: questId, session: self)
    }

    public func makeQuestListViewModel() -> QuestListViewModel {
        QuestListViewModel(session: self)
    }

    public func makeGameDayViewModel() -> GameDayViewModel {
        GameDayViewModel(session: self)
    }

    public func makeCalendarViewModel(calendar: [GameDay], currentDayNumber: Int) -> CalendarViewModel {
        CalendarViewModel(calendar: calendar, currentDayNumber: currentDayNumber)
    }

    public func makeInventoryViewModel() -> InventoryViewModel {
        InventoryViewModel(session: self)
    }
}
