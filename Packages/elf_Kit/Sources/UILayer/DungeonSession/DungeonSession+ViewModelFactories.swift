//
//  DungeonSession+ViewModelFactories.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// UI-layer extension on `DungeonSession` that vends ViewModels for the
/// dungeon-tab screens. Mirrors the `GameSession` extension pattern so the
/// data-layer file stays free of UI references.
@MainActor
extension DungeonSession {

    public func makeOverviewViewModel() -> DungeonOverviewViewModel {
        DungeonOverviewViewModel(session: self)
    }

    public func makeSquadViewModel() -> DungeonSquadViewModel {
        DungeonSquadViewModel(session: self)
    }

    public func makeMapViewModel() -> DungeonMapViewModel {
        DungeonMapViewModel(session: self)
    }
}
