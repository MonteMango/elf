//
//  DungeonRouteView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

/// Adapter for `DungeonScreen`. The existence guard for the active
/// `DungeonSession` lives here (in `body`, not in `DungeonScreen.init`): when a
/// run ends — e.g. "Finish" or a hero death pops back to Game Day — this body
/// re-evaluates and renders nothing instead of constructing the screen against
/// a released session, which would trap. See `BattleFightRouteView` for the
/// sibling pattern.
struct DungeonRouteView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        if let session = coordinator.gameSession,
           let dayStateVM = coordinator.dayStateViewModel,
           let dungeonSession = session.dungeonSession {
            DungeonScreen(gameSession: session, dungeonSession: dungeonSession)
                .environment(dayStateVM)
        }
    }
}
