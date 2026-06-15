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
    @Environment(AppRouter.self) private var router
    let battle: Battle

    var body: some View {
        BattleFightScreen(
            battle: battle,
            session: coordinator.gameSession,
            // The launcher owns post-battle side effects and returns the result
            // to show. Dungeon: fold squad state, no rewards/save (the dungeon
            // flow saves). Hunt: apply XP/drops + save. Dev (no session): the VM
            // computes a display-only result.
            onBattleConcluded: { outcome, finalLeftTeam in
                // An active dungeon run owns the battle — the authoritative
                // "this battle belongs to the dungeon" signal. More robust than
                // `isInRun` (a derived currentRoom != nil condition).
                if let session = coordinator.gameSession, let dungeon = session.dungeonSession {
                    let result = dungeon.concludeRoomBattle(outcome: outcome, finalLeftTeam: finalLeftTeam)
                    // Checkpoint the cleared room. On a downed hero the run ends
                    // from the result screen (which saves the cleared run), so we
                    // skip persisting a downed-in-dungeon state here.
                    if !dungeon.heroIsDowned {
                        session.saveInBackground()
                    }
                    return result
                }
                if let session = coordinator.gameSession {
                    return session.concludeHuntBattle(battle: battle, outcome: outcome)
                }
                // Dev BattleSetup (no game session): no rewards, no result
                // overlay — just auto-close the battle screen.
                router.pop()
                return nil
            }
        )
    }
}
