//
//  BattleFightRouteView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

/// Specialized adapter for `BattleFightScreen`, which accepts an **optional** session
/// (the dev BattleSetup flow reaches it without an active game session).
struct BattleFightRouteView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let battle: Battle

    var body: some View {
        BattleFightScreen(
            battle: battle,
            session: coordinator.gameSession,
            // When a dungeon run is active, fold the finished battle's final
            // squad state back into it. No-op for hunt / dev battles (no run).
            onConclude: { finalLeftTeam, outcome in
                coordinator.gameSession?.dungeonSession?
                    .applyBattleOutcome(finalLeftTeam: finalLeftTeam, outcome: outcome)
            }
        )
    }
}
